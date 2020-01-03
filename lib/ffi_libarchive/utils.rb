# frozen_string_literal: true

require 'ffi'

module Archive
  module Utils
    module LibC
      extend FFI::Library
      ffi_lib FFI::Library::LIBC

      begin
        attach_function :chdir, [:string], :int
      rescue FFI::NotFoundError
        attach_function :chdir, :_chdir, [:string], :int
      end
    end

    class << self
      # @param [String] dir
      # @return [Integer]
      def change_cwd(dir)
        if block_given?
          cwd = Dir.getwd
          change_cwd dir

          begin
            yield
          ensure
            change_cwd cwd
          end
        else
          rc = Dir.chdir dir
          rc != 0 ? rc : LibC.chdir(dir)
        end
      end
    end
  end
end
