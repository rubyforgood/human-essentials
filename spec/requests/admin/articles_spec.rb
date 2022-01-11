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
        post admin_articles_path(article: attributes_for(:article).merge(question: ""))
        expect(subject).to render_template("new")
        expect(flash[:error]).to be_present
        expect(Article.all.count).to eq 0
      end

      it "article answers can't be blank" do
        post admin_articles_path(article: attributes_for(:article).merge(content: ""))
        expect(subject).to render_template("new")
        expect(flash[:error]).to be_present
        expect(Article.all.count).to eq 0
      end

      it "article for_banks and for_partners attributes can't both be false" do
        post admin_articles_path(article: attributes_for(:article).merge(
          for_banks: false,
          for_partners: false
        ))
        expect(subject).to render_template("new")
        expect(flash[:error]).to be_present
      end
    end

    describe "GET #edit" do
      it "lets the user load the edit article page" do
        article = create(:article)
        get edit_admin_article_path(article)
        expect(response).to be_successful
      end
    end

    describe "PATCH #update" do
      it "lets the user update articles" do
        article = create(:article)
        patch admin_article_path(
          {
            id: article.id,
            article: {
              question: "updated question",
              for_banks: false,
              for_partners: true
            }
          }
        )
        expect(response).to be_redirect
        article.reload
        expect(article.question).to eq "updated question"
        expect(article.for_banks).to eq false
        expect(article.for_partners).to eq true
      end

      it "article questions can't be blank" do
        article = create(:article)
        patch admin_article_path(
          {
            id: article.id,
            article: {
              question: ""
            }
          }
        )
        expect(subject).to render_template("edit")
        expect(flash[:error]).to be_present
        article.reload
        expect(article.question).to eq "question"
      end

      it "article answers can't be blank" do
        article = create(:article)
        origional_answer = article.content
        patch admin_article_path(
          {
            id: article.id,
            article: {
              content: ""
            }
          }
        )
        expect(subject).to render_template("edit")
        expect(flash[:error]).to be_present
        article.reload
        expect(article.content).to eq origional_answer
      end

      it "article for_banks and for_partners attributes can't both be false" do
        article = create(:article)
        article.update(for_banks: true)
        article.update(for_partners: true)
        patch admin_article_path(
          {
            id: article.id,
            article: {
              for_banks: false,
              for_partners: false
            }
          }
        )
        expect(subject).to render_template("edit")
        expect(flash[:error]).to be_present
        article.reload
        expect(article.for_banks).to eq true
        expect(article.for_partners).to eq true
      end
    end

    describe "DELETE #destroy" do
      it "lets the user delete articles" do
        article = create(:article)
        delete admin_article_path(article)
        expect(response).to be_redirect
        expect(Article.all.count).to eq 0
      end
    end
  end
end
