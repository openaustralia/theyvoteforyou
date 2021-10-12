require "spec_helper"

feature "Policies" do
  given(:user) { create(:user, confirmed_at: Time.now) }

  background do
    # TODO: Remove this hack to delete fixtures
    Member.delete_all
    User.delete_all

    visit new_user_session_path
    within "#new_user" do
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password
    end
    click_button "Log in"
  end

  scenario "successfully creating new" do
    visit new_policy_path
    within "#new_policy" do
      fill_in "If you are for", with: "the creation of quality policies on this site"
      fill_in "you believe that", with: "quality contributions are the bedrock of community projects"
    end
    click_button "Make Policy"
    expect(page).to have_content "Successfully made new policy"
    expect(page).to have_content "For the creation of quality policies on this site"
    expect(page).to have_content "Quality contributions are the bedrock of community projects"
  end

  scenario "editing existing" do
    PaperTrail.whodunnit = user.id

    policy = create(:policy, name: "test", description: "testing")
    visit edit_policy_path(policy)
    within ".edit_policy" do
      fill_in "If you are for", with: "test2"
      fill_in "you believe that", with: "testing too"
    end
    click_button "Save title and text"
    policy.reload
    expect(policy.name).to eql "test2"
    expect(policy.description).to eql "testing too"
  end
end
