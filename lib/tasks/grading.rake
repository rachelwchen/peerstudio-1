namespace :grading do
	
	desc "push grades to coursera"
	task :push_grades => :environment do
		logger = Rails.logger
		users = User.all

		logger.info "Pushing grades for #{users.count} users"
		users.each	do |user| 
			logger.info "Attempting to push grades for #{user.email} (#{user.cid})"
			Answer.push_grades(user, 0)

			if user.id % 10 == 0
				print "."
				$stdout.flush
			end
		end
	end

	desc "ASSIGNMENT=id; Grade all students for an assignment"
	task :regrade => :environment do 
		assignment_id = ENV['ASSIGNMENT']

		###
		# setup variables
		###
		milestone_credit = 1
		exchange_review_credit = 1
		paired_review_credit = 1 #half for each half of the pair
		final_review_credit = 1
		paired_review_threshold = 2
		final_review_threshold = 3
		final_draft_name = "Final Draft"

		puts "Regrading Assignment #{assignment_id}"
		assignment = Assignment.find(assignment_id)
		AssignmentGrade.destroy_all(assignment_id: assignment.id)
		Enrollment.where(course: assignment.course).each do |enrollment|
			student = enrollment.user
			#First set participation credit
			assignment.milestones.each do |m|
				answer = Answer.tagged_with(m).where(assignment: assignment, active:true)
				if answer.count > 0
					# puts "Found answer for student #{student.name} and milestone #{m}"
					AssignmentGrade.create(user: student, assignment: assignment, grade_type: "Participation credit: #{m}", credit: milestone_credit)
				end
			end

			Review.where(user: student, assignment: assignment, active: true).group(:review_type).count.each do |review_type, review_count|
				if review_type == "exchange"
					AssignmentGrade.create(user: student, assignment: assignment, grade_type: "Participation credit for exchange review", credit: exchange_review_credit, marked_reviews: review_count)
				end

				if review_type == "final" and review_count >= final_review_threshold
					AssignmentGrade.create(user: student, assignment: assignment, grade_type: "Participation credit for final review", credit: final_review_credit, marked_reviews: review_count)
				end
			end

			paired_reviews = Review.where("(user_id = ? or copilot_email= ?) and review_type='paired' and active = ? and assignment_id=?", student.id, student.email, true, assignment.id)
			if paired_reviews.count > paired_review_threshold
				AssignmentGrade.create(user: student, assignment: assignment, grade_type: "Participation credit for paired review", credit: paired_review_credit, marked_reviews: paired_reviews.count)
			end

			##grades for assignment rubrics
			final_answer = Answer.where(user: student, active: true).tagged_with(final_draft_name).first
			if !final_answer.nil?
				final_reviews = Review.where(review_type: "final", active: true, answer_id: final_answer.id)
				assignment.rubric_items.each do |rubric|
					rubric.answer_attributes.each do |answer_attribute|
						marked_count = answer_attribute.feedback_items.where(review_id: final_reviews).count
						attribute_credit = (if marked_count >= 2
											 answer_attribute.score
											elsif final_reviews.count > 0
											 answer_attribute.score * marked_count/final_reviews.count
											else
												0
											end)
						AssignmentGrade.create(user: student, assignment: assignment, 
							grade_type: "#{rubric.short_title}: #{answer_attribute.description}", 
							credit: attribute_credit, 
							marked_reviews: marked_count, 
							total_reviews: final_reviews.count, 
							rubric_item_id: rubric.id)
					end
				end
			end
		end
	end
end