_            = require 'underscore'
Backbone     = require 'backbone'
template     = -> require('./template.jade') arguments...
SaveControls = require('./save_controls.coffee')
sd           = require('sharify').data

module.exports = class FillwidthView extends Backbone.View

  initialize: (options) ->
    { @seeMore, @fetchOptions, @artworkCollection } = options
    @page = 1
    @fetched = 0
    @listenTo @collection, 'request', @renderSpinner
    @listenTo @collection, 'sync', @render
    @

  renderSpinner: ->
    @$('.fillwidth-see-more').attr 'data-state', 'loading'

  render: =>
    @$el.html template artworks: @collection.models, seeMore: @seeMore
    maxHeight = parseInt(@$('img').first().css('max-height')) or 260
    @$('li').css 'min-height': maxHeight + 90
    @$('li .fillwidth-img-container').height maxHeight
    @$('ul').fillwidth
      imageDimensions: @collection.fillwidthDimensions(maxHeight)
    @handleSeeMore() if @seeMore
    @initializeArtworks @collection

  initializeArtworks: (artworks) ->
    $list = @$('.fillwidth-img-container')
    return unless $list.length > 0
    listItems =
      for artwork, index in artworks.models
        item = new SaveControls
          artworkCollection: @artworkCollection
          model: artwork
          el: $($list[index]).find('.overlay-container')

    # Todo: setup impression tracking
    # @initializeImpressionTracking listItems, $list
    @syncSavedArtworks(artworks) if @artworkCollection

  syncSavedArtworks: (artworks) ->
    @artworkCollection.addRepoArtworks artworks
    _.delay (=> @artworkCollection.syncSavedArtworks()), 500

  handleSeeMore: ->
    if @page is 2
      _.defer @hideFirstRow
    if @collection.models.length < @fetched
      @hideSeeMore()

  hideSeeMore: ->
    @$('.fillwidth-see-more').hide()

  hideFirstRow: =>
    firstItem = @$('ul li').first()
    firstItemTop = firstItem.offset().top if firstItem.length
    @$('ul li').each ->
      $(@).hide() if $(@).offset().top > firstItemTop

  events:
    'click .fillwidth-see-more': 'nextPage'

  nextPage: (evt, size=20) ->
    @fetched += size
    @collection.fetch
      remove: false
      data: _.extend { size: size, page: @page++ }, @fetchOptions

  # Remove items that are not shown to reduce DOM footprint
  removeHiddenItems: ->
    @$('ul li:hidden').remove()
