# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# $('.typeahead-usernames').typeahead({
#   # name: 'accounts',
#   local: ['timtrueman', 'JakeHarding', 'vskarich']
# })

$(document).on 'ready page:load', () ->
	$('#write').click showSubmitWarning
	$('#give-feedback').click showReviewWarning
	$("#typed_review_type").change(()->
		$("#typed_review_email").show().attr("placeholder","Choose a review type first")
		$("#start_review").val("Start review")
		switch $(this).val()
			when "paired"
				$("#typed_review_email").attr("placeholder", "Pairing partner's email")
				$("#start_review").val("Start paired review")
			when "exchange"
				$("#typed_review_email").attr("placeholder", "Exchanging partner's email")
				$("#start_review").val("Start exchange review")
			when "final"
				$("#typed_review_email").hide()
				$("#start_review").val("Start final review")
	)

	$('#flipbook-reveal-author').click () ->
		$(this).text($(this).data('author'))
		return false

showSubmitWarning = (el) ->
	if($(this).data('showLateWarning'))
		$('#submit-late-work').modal('show')
		return false
	else
		return true

showReviewWarning = (el) ->
	if($(this).data('showLateWarning'))
		$('#review-late-work').modal('show')
		return false
	else
		return true