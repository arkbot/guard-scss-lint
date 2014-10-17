# coding: utf-8

module Guard
  # A workaround for declaring `class ScssLint`
  # before `class ScssLint < Guard` in scss-lint.rb
  module ScssLintVersion
    # http://semver.org/
    MAJOR = 0
    MINOR = 1
    PATCH = 0

    def self.to_s
      [MAJOR, MINOR, PATCH].join('.')
    end
  end
end
