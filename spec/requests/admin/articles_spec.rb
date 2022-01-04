require 'rails_helper'

RSpec.describe "Admin::Articles", type: :request do
  context "while signed in as a super admin" do
    before do
      sign_in(@super_admin_no_org)
    end

    describe "GET #new" do
      it "lets the user load the new article page" do
        get new_admin_article_path
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      it "lets the user create articles" do
        post admin_articles_path(article: attributes_for(:article))
        expect(response).to be_redirect
        expect(Article.all.count).to eq 1
      end
    end
  end
end
