require 'spec_helper'

feature 'Viewing user stats' do
  background do
    3.times { create(:user) }
  end

  scenario 'successfully' do
    visit users_path

    expect(page).to have_content '3 people have signed up'
  end
end
