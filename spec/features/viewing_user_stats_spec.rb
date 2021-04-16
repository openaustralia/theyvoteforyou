require 'spec_helper'

feature 'Viewing user stats' do
  given(:user1) { create(:user)}
  given(:user2) { create(:user)}
  given(:user3) { create(:user)}

  given(:policy1) { create(:policy, user: user1, name: 'shiny coins') }
  given(:policy2) { create(:policy, user: user2, name: 'dusty ponies') }
  given(:policy3) { create(:provisional_policy, user: user3, name: 'more libraries') }

  background do
    # TODO: Remove this hack to delete fixtures
    User.delete_all
    Policy.delete_all

    policy1.watches.create!(user: user1)
    policy1.watches.create!(user: user2)
    policy1.watches.create!(user: user3)
    policy2.watches.create!(user: user1)
    policy2.watches.create!(user: user2)
    policy3.watches.create!(user: user1)
  end

  scenario 'successfully' do
    visit user_stats_path

    expect(page).to have_content '3 people have signed up'
  end

  context 'when they have have subscriptions' do
    scenario 'successfully' do
      visit user_stats_path

      expect(page).to have_content "For shiny coins\n3 subscribers"
      expect(page).to have_content "For dusty ponies\n2 subscriber"
      expect(page).to have_content "For more libraries\n1 subscriber"
    end
  end
end
