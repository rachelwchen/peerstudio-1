require 'csv'
class User < ActiveRecord::Base
	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
				 :recoverable, :rememberable, :trackable, :validatable

	devise :omniauthable, :omniauth_providers=>[:coursera,:stanford]


	validate do |user|
		user.errors[:base] << ("You must choose whether you want to participate in our research.") if user.consented.nil?
	end

	has_many :assessments
	has_many :verifications

	#This is necessary for doing things like current_user.instructor_for?
	def instructor_for?(course)
		return false if !self.view_mode.nil? and self.view_mode== "student"
		self.admin? or !course.instructors.include?(self).nil?
	end

	def instructor_for_some_course?
		self.admin? or !Enrollment.where(instructor: true, user: self).empty?
	end

	#This was for the L@S paper.
	def get_and_store_experimental_condition!(course)
		# if id%5 == 0
		# 	return "baseline"
		# elsif id%2 == 0
		# 	return "verify"
		# else
		# 	return "identify"
		# end
		if !course.waitlist_condition
			return "normal"
		end

		if self.experimental_group.blank?
			self.experimental_group = self.experimental_condition(course)
			# self.save! #don't save, we have some validation issue.
			self.save!
		end
		return self.experimental_group
	end

	def experimental_condition(course)
		if !self.experimental_group.blank?
			return self.experimental_group
		end

		# #begin vineet
		# if self.email="2@test.com"
		# 	return "batched_email"
		# end
		# #end vineet

		if !course.waitlist_condition
			return "normal"
		elsif id%3==0
			return "normal"
		elsif id%3 == 1
			return "no_early_feedback"
		elsif id%3 == 2
			return "batched_email"
		else
			return "normal"
		end
	end



	class ImportJob <  Struct.new(:file_text)
		def perform
			print "STARTing job"
			spreadsheet = CSV.parse(file_text, {:headers => :first_row})
			spreadsheet.each do |row|
				owning_user = User.find_by_email(row["email"].downcase)
				if owning_user.nil?
				#this is a dummy password
					owning_user = User.new :password => Devise.friendly_token[0,20], :email=> row["email"]
				end

				owning_user.cid= row["coursera_id"]
				owning_user.save!
				# print "Answer saved"
			end

			print "FINISHing job"
		end
	end

	def self.import(file)
		raise "Unknown file type" if File.extname(file.original_filename) != ".csv"
		Delayed::Job.enqueue ImportJob.new(file.read)
	end
end
