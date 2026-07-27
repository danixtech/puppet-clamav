# frozen_string_literal: true

openvox = Gem::Specification.find_by_name('openvox', ENV.fetch('PUPPET_GEM_VERSION', '>= 0'))
openvox_lib = File.join(openvox.full_gem_path, 'lib')

$LOAD_PATH.delete(openvox_lib)
$LOAD_PATH.unshift(openvox_lib)
