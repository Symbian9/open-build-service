require 'browser_helper'

RSpec.feature 'Groups', type: :feature, js: true do
  let(:admin) { create(:admin_user, login: 'king') }
  let(:user_1) { create(:confirmed_user, login: 'eisendieter') }
  let!(:group_1) { create(:group, title: 'test_group', users: [admin, user_1]) }
  let!(:group_2) { create(:group, title: 'test_group_b') }

  before do
    login admin
  end

  def group_in_datatable(page, group)
    expect(page).to have_link(group.title, href: group_show_path(group))
    group.users.each { |user| expect(page).to have_link(user.login, href: user_show_path(user)) }
  end

  scenario 'visit groups index page' do
    visit groups_path

    [group_1, group_2].each do |group|
      group_in_datatable(page, group)
    end

    expect(page).to have_content('Showing 1 to 2 of 2 entries')
  end

  scenario 'visit group show page' do
    visit group_show_path(group_1)

    expect(page).to have_content('Incoming Reviews')
    expect(page).to have_content('Incoming Requests')
    expect(page).to have_content('All Requests')
    find('#group-members-tab').click

    expect(page).to have_link('Add Member')
    group_1.users.each { |user| expect(page).to have_link(user.login, href: user_show_path(user)) }
  end

  scenario 'create a group' do
    visit groups_path

    click_link('Create Group', href: group_new_path)

    new_group_title = 'group_123'
    fill_in('group_title', with: new_group_title)
    # Typing a comma after a user login selects it (just like clicking on the autocomplete menu popping up). It's a built-in feature of the tokenfield
    fill_in('group-members_tag', with: "#{admin},#{user_1},")

    expect { click_button('Create') }.to change(Group, :count).by(1)
    expect(page).to have_content("Group '#{new_group_title}' successfully created.")
    group_in_datatable(page, Group.find_by(title: new_group_title))
  end

  scenario 'remove a member from a group' do
    visit group_show_path(group_1)

    within(find('div.group-user', text: admin.login)) do
      click_link('Remove member from group')
    end

    expect(page).to have_content("Removed user from group '#{group_1}'")
    expect(group_1.reload.users.map(&:login)).to eq([user_1.login])
  end

  scenario 'give maintainer rights to a group member' do
    visit group_show_path(group_1)

    within(find('div.group-user', text: admin.login)) do
      check('Maintainer', allow_label_click: true)
    end

    expect(page).to have_content("Gave maintainer rights to #{admin}")
  end

  scenario 'add a group member' do
    visit group_show_path(group_2)

    click_link('Add Member')

    within('#add-group-user-modal') do
      fill_in('user_login', with: admin.login)

      expect do
        click_button('Accept')
        group_2.reload
      end.to change { group_2.users.count }.by(1)
    end

    expect(page).to have_content("Added user '#{admin}' to group")

    visit groups_path
    group_in_datatable(page, group_2)
  end
end
