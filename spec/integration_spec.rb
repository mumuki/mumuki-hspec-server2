require_relative '../spec/spec_helper' #FIXME remove. There must be an issue with mumukit-bridge requires

require 'mumukit/bridge'

describe 'runner' do
  let(:bridge) { Mumukit::Bridge::Bridge.new('http://localhost:4567') }
  before(:all) do
    @pid = Process.spawn 'rackup -p 4567', err: '/dev/null'
    sleep 3
  end
  after(:all) { Process.kill 'TERM', @pid }

  let(:test) do
    <<HASKELL
it "x" $ do
  x `shouldBe` 1
HASKELL
  end

  let(:ok_content) do
    <<HASKELL
x = 1
HASKELL
  end

  let(:nok_content) do
    <<HASKELL
x = 2
HASKELL
  end

  let(:malicius_content) do
    <<HASKELL
import System.IO.Unsafe

x = 1
HASKELL
  end

  it 'answers a valid hash when submission is ok' do
    response = bridge.run_tests!(test: test,
                                 extra: '',
                                 content: ok_content,
                                 expectations: [])

    expect(response).to eq(response_type: :structured,
                           test_results: [{title: 'x', status: :passed, result: ''}],
                           status: :passed,
                           feedback: '',
                           expectation_results: [],
                           result: '')
  end

  it 'answers a valid hash when submission is not ok' do
    response = bridge.run_tests!(test: test,
                                 extra: '',
                                 content: nok_content,
                                 expectations: [])

    expect(response).to eq(response_type: :structured,
                           test_results: [{title: 'x', status: :failed, result: "expected: 1\n but got: 2"}],
                           status: :failed,
                           feedback: '',
                           expectation_results: [],
                           result: '')
  end

  it 'answers a valid hash when submission is invalid' do
    response = bridge.run_tests!(test: test,
                                 extra: '',
                                 content: malicius_content,
                                 expectations: [])

    expect(response).to eq(response_type: :unstructured,
                           status: :aborted,
                           feedback: '',
                           expectation_results: [],
                           test_results: [],
                           result: 'you can not use unsafe io')
  end

end