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

      it "article questions can't be blank" do
        post admin_articles_path(article: attributes_for(:article).merge(question: nil))
        expect(subject).to render_template("new")
        expect(flash[:error]).to be_present
        expect(Article.all.count).to eq 0
      end

      it "article for_organizations and for_partners attributes can't both be false" do
        post admin_articles_path(article: attributes_for(:article).merge(
          for_organizations: false,
          for_partners: false
        ))
        expect(subject).to render_template("new")
        expect(flash[:error]).to be_present
      end
    end
  end
end
