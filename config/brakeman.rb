require 'brakeman'

# False positives are tracked on config/brakeman.ignore file
tracker = Brakeman.run :app_path => "."

puts tracker.report

if tracker.filtered_warnings.empty?
  exit 0
else
  exit 1
end
