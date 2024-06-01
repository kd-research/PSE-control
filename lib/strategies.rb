# @!parse STRATEGY::NOINIT = false
# @!parse STRATEGY::KEEP_AF_CONFIG = true
module STRATEGY
  defaults = {
    NOINIT: false,
    KEEP_AF_CONFIG: true
  }

  defaults.each do |key, value|
    if !const_defined?(key)
      const_set(key, value)
    end
  end
end
