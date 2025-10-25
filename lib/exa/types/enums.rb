# frozen_string_literal: true

module Exa
  module Types
    class SearchType < T::Enum
      enums do
        Keyword = new(:keyword)
        Neural = new(:neural)
        Hybrid = new(:hybrid)
        Fast = new(:fast)
        Deep = new(:deep)
        Auto = new(:auto)
      end
    end

    class Category < T::Enum
      enums do
        Company = new(:company)
        ResearchPaper = new(:research_paper)
        News = new(:news)
        Pdf = new(:pdf)
        Github = new(:github)
        Tweet = new(:tweet)
        PersonalSite = new(:personal_site)
        LinkedinProfile = new(:linkedin_profile)
        FinancialReport = new(:financial_report)
      end
    end

    class LivecrawlMode < T::Enum
      enums do
        Never = new(:never)
        Fallback = new(:fallback)
        Always = new(:always)
        Auto = new(:auto)
        Preferred = new(:preferred)
      end
    end

    class ResearchModel < T::Enum
      enums do
        Fast = new(:"exa-research-fast")
        Standard = new(:"exa-research-standard")
      end
    end
  end
end
