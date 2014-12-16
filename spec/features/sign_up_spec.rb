require 'spec_helper'

feature 'Signing up' do
  background do
    # TODO: Remove this hack to delete fixtures
    Member.delete_all
    User.delete_all

    create :member
  end

  scenario 'Signing up with valid details' do
    visit '/'
    click_link 'Sign up'
    expect(page).to have_content 'Sign up to help unlock parliament'
    within('#new_user') do
      fill_in 'Email', with: 'henare@oaf.org.au'
      fill_in 'Username', with: 'Henare Degan'
      fill_in 'Password', with: 'password'
    end
    click_button 'Sign up'
    expect(page).to have_content 'now check your inbox'
  end
end
