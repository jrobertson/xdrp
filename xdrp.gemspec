Gem::Specification.new do |s|
  s.name = 'xdrp'
  s.version = '0.2.2'
  s.summary = 'A basic macro recorder for GNU/Linux which uses program ' + 
      'xinput to capture input events.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/xdrp.rb']
  s.add_runtime_dependency('xdo', '~> 0.0', '>=0.0.4')
  s.add_runtime_dependency('rxfhelper', '~> 1.1', '>=1.1.3')
  s.add_runtime_dependency('xinput_wrapper', '~> 0.8', '>=0.8.1')    
  s.add_runtime_dependency('ruby-wmctrl', '~> 0.0', '>=0.0.8')
  s.add_runtime_dependency('keystroker', '~> 0.3', '>=0.3.1')
  s.signing_key = '../privatekeys/xdrp.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/xdrp'
  s.required_ruby_version = '>= 3.0.2'
end
