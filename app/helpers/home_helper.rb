module HomeHelper
  def search_people_form_placeholder_text
    if Member.any?
      "e.g. #{Member.random_postcode} or #{Member.random_current.name_without_title}"
    else
      nil
    end
  end
end
