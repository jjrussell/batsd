xml.instruct!
xml.user do
  xml.id @user.key #This wont work as ARes expects id of type integer
  xml.email @user.get('email')
  xml.user_name @user.get('user_name')
  xml.name ''
  xml.partner_id @user.get('partner_id')
  xml.group ''
end