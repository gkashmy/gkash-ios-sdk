Pod::Spec.new do |spec|
  spec.name          = 'GkashPayment'
  spec.version       = '0.1'
  spec.license       = 'MIT'
  spec.homepage      = 'https://github.com/gkashmy/gkash-ios-sdk'
  spec.authors       = { 'Gkash developer' => 'developers@gkash.com' }
  spec.summary       = 'This library allows you to integrate Gkash Payment Gateway into your IOS App.'
  spec.source        = { :git => 'https://github.com/gkashmy/gkash-ios-sdk.git', :tag => spec.version }
  spec.swift_version = '5.0'
spec.vendored_frameworks = 'GkashPayment.framework'

end