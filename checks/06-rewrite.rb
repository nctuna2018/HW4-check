class Checker
	module CheckRewrite
		def check_rewrite
			smtp('TA', @private_key) do |s|
				s.sendmail("Subject: test G\n\ntest G\n", "TA@mail.#{@base_domain}", "dkimtest@mail.tzute.nasa")
			end
		rescue
		end

		def check!
			super

			check_rewrite
		end
	end
end
