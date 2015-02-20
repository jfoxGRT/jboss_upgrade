class Session < ActiveRecord::SessionStore::Session

      attr_reader :user_id
      attr_writer :user_id
      before_save :update_user_id

      def update_user_id
	  puts "Updating User ID: #{user_id}"
          write_attribute( :user_id, data[:user] )
      end

end

# == Schema Information
#
# Table name: sessions
#
#  id         :integer(10)     not null, primary key
#  session_id :string(255)
#  data       :text
#  updated_at :datetime
#  user_id    :integer(10)
#

