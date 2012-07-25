class DTK::Common::GritAdapter::FileAccess
  module DiffMixin
    def diff(*args)
      diff_comamnd_args = 
        case args.size
         when 1 then [@branch,args[0]]
         when 2 then args
          else raise Error.new("diff must have 1 or 2 arguments")
        end
      grit_diffs = @grit_repo.diff(*diff_comamnd_args)
      array_diff_hashes = grit_diffs.map do |diff|
        Diff::Attributes.inject(Hash.new) do |h,a|
          val = diff.send(a)
          val ?  h.merge(a => val) : h
        end
      end
      Diffs.new(array_diff_hashes)
    end

    class Diffs < Array
      ::DTK::Common.r8_require_common('hash_object')
      class Summary < ::DTK::Common::SimpleHashObject
        def any_diffs?()
          !keys().empty?
        end
        def any_added_or_deleted_files?()
          !!(self[:files_renamed] or self[:files_added] or self[:files_deleted])
        end
        
        def meta_file_changed?()
          self[:files_modified] and !!self[:files_modified].find{|r|r[:path] =~ /^r8meta/}
        end

        #note: in paths_to_add and paths_to_delete rename appears both since rename can be accomplsihed by a add + a delete 
        def paths_to_add()
          (self[:files_added]||[]).map{|r|r[:path]} + (self[:files_renamed]||[]).map{|r|r[:new_path]}
        end
        def paths_to_delete()
          (self[:files_deleted]||[]).map{|r|r[:path]} + (self[:files_renamed]||[]).map{|r|r[:old_path]}
        end
      end
      
      def initialize(array_diff_hashes)
        super(array_diff_hashes.map{|hash|Diff.new(hash)})
      end

      #returns a hash with keys :file_renamed, :file_added, :file_deleted, :file_modified
      def ret_summary()
        [:renamed,:added,:deleted,:modified].inject(Summary.new) do |h,cnd|
          res = map{|diff|diff.send("file_#{cnd}".to_sym)}.compact
          res.empty? ? h : h.merge("files_#{cnd}".to_sym => res)
        end
      end
    end

    class Diff
      Attributes = [:new_file,:renamed_file,:deleted_file,:a_path,:b_path,:diff]
      AttributeAssignFn = Attributes.inject(Hash.new){|h,a|h.merge(a => "#{a}=".to_sym)}
      def initialize(hash_input)
        hash_input.each{|a,v|send(AttributeAssignFn[a],v)}
      end
      
      def file_added()
        @new_file && {:path => @a_path}
      end

      def file_renamed()
        @renamed_file && {:old_path => @b_path, :new_path => @a_path}
      end

      def file_deleted()
        @deleted_file && {:path => @a_path}
      end

      def file_modified()
        ((@new_file or @deleted_file or @renamed_file) ? nil : true) && {:path => @a_path} 
      end
     private
      attr_writer(*Attributes) 
    end
  end
end
