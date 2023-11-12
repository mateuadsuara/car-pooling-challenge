require 'rspec'
require 'keyed_queue'
require 'set'

module KeyedQueue
  RSpec.describe KeyedQueue do
    let(:q) { described_class.new }

    it 'starts empty' do
      expect(q.length).to eq(0)
      expect(q.to_a).to eq([])
    end

    it 'with 1 element' do
      q.push('e1')
      expect(q.length).to eq(1)
      expect(q.to_a).to eq(['e1'])
    end

    it 'remove the only element' do
      q.push('e1')
      q.remove('e1')
      expect(q.length).to eq(0)
      expect(q.to_a).to eq([])
    end

    it 'errors on existing element' do
      q.push('e1')
      expect{q.push('e1')}.to raise_error(Duplicate)
    end

    it 'does not error if previously existing element is removed' do
      q.push('e1')
      q.remove('e1')
      expect{q.push('e1')}.not_to raise_error
    end

    it 'errors on missing element' do
      expect{q.remove('e1')}.to raise_error(Missing)
    end

    it 'pushes elements to the end' do
      q.push(5)
      q.push(2)
      q.push(6)
      q.push(4)
      expect(q.to_a).to eq([5, 2, 6, 4])
    end

    it 'removing elements preserve order of the other elements' do
      q.push(5)
      q.push(2)
      q.push(6)
      q.push(4)
      q.remove(2)
      q.push(3)
      q.remove(4)
      q.push(2)

      es = []
      q.each do |e|
        es << e
      end

      expected_elements = [5, 6, 3, 2]
      expect(es).to eq(expected_elements)
      expect(q.to_a).to eq(expected_elements)
    end

    it 'can remove current element while iterating' do
      q.push(5)
      q.push(2)
      q.push(6)
      q.push(4)

      visited = []
      q.each do |e|
        visited << e
        if e == 2
          q.remove(e)
        end
      end

      expect(visited).to eq([5, 2, 6, 4])
      expect(q.to_a).to eq([5, 6, 4])
    end

    it 'skips future elements if removed while iterating' do
      q.push(5)
      q.push(2)
      q.push(6)
      q.push(4)

      visited = []
      q.each do |e|
        visited << e
        if e == 2
          q.remove(5)
          q.remove(e)
          q.remove(6)
        end
      end

      expect(visited).to eq([5, 2, 4])
      expect(q.to_a).to eq([4])
    end
  end
end
