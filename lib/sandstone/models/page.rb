module Sandstone
  module Models
    module Page
      def self.included(base)
        base.class_eval do
          after_save :retire_old_published_versions

          self.acts_as_versioned
          acts_as_tree

          has_many :audits, :as => :record, :dependent => :destroy
          belongs_to :page_template
          belongs_to :editor
          validates_uniqueness_of :path
          validates_presence_of :status, :content
        end

        base.send(:include, InstanceMethods)
        base.send(:extend, ClassMethods)
      end

      module InstanceMethods
        STATUSES = ['new', 'pending', 'published']

        def layout
          page_template ? page_template.name.tableize : 'public'
        end

        def draft=(value)
          self.status = 'new'
        end

        def approve=(value)
          self.status = 'pending'
        end

        def publish=(value)
          self.status = 'published'
        end

        def retire_old_published_versions
          self.versions.update_all('status = "retired"', ['version < ? AND status = ?', self.version, 'published']) if self.status == 'published'
        end
      end

      module ClassMethods
        def find_roots(published_only = false)
          unless published_only
            find(:all, :conditions => {:parent_id => nil}, :include => :page_template)
          else
            ::Page::Version.find(:all, :conditions => {:parent_id => nil, :status => 'published'})
          end
        end

        def find_pending
          find_all_by_status('pending')
        end
      end
    end
  end
end