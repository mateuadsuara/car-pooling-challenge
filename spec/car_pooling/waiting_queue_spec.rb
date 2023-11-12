require 'rspec'
require 'car_pooling/waiting_queue'

module CarPooling
  RSpec.describe WaitingQueue do
    let(:q) { described_class.new }

    it 'starts empty' do
      expect(q.length).to eq(0)
      expect(q.to_a).to eq([
      ])
    end

    it 'enqueue 1 time' do
      id = 10
      space = 3

      q.enqueue(id, space)

      expect(q.length).to eq(1)
      expect(q.to_a).to eq([
        [id, space]
      ])
    end

    it 'enqueue adds to the end' do
      q.enqueue(5, 3)
      q.enqueue(2, 4)
      q.enqueue(6, 2)
      q.enqueue(4, 3)

      expect(q.length).to eq(4)
      expect(q.to_a).to eq([
        [5, 3],
        [2, 4],
        [6, 2],
        [4, 3]
      ])
    end

    it 'remove when previously enqueued' do
      id = 10

      q.enqueue(id, 3)
      q.remove(id)

      expect(q.length).to eq(0)
      expect(q.to_a).to eq([
      ])
    end

    it 'remove preserves order' do
      q.enqueue(5, 1)
      q.enqueue(2, 2)
      q.enqueue(6, 3)
      q.enqueue(4, 4)
      q.remove(2)
      q.enqueue(3, 5)
      q.remove(4)
      q.enqueue(2, 6)

      expect(q.length).to eq(4)
      expect(q.to_a).to eq([
        [5, 1],
        [6, 3],
        [3, 5],
        [2, 6]
      ])
    end

    it 'errors on enqueue when previously enqueued' do
      id = 10
      space = 3

      q.enqueue(id, space)

      expect{q.enqueue(id, space)}
        .to raise_error(WaitingQueue::Duplicate)
    end

    it 'does not error on enqueue when removed' do
      id = 10
      space = 3

      q.enqueue(id, space)
      q.remove(id)

      expect{q.enqueue(id, space)}
        .not_to raise_error
    end

    it 'errors on remove when missing id' do
      id = 10

      expect{q.remove(id)}
        .to raise_error(WaitingQueue::Missing)
    end

    describe 'next_fitting_in' do
      it 'is nil when nothing in the queue' do
        (0..10).each do |s|
          expect(q.next_fitting_in(s)).to eq(nil)
        end
      end

      it 'returns the only available one for exact space' do
        id = 10
        space = 1

        q.enqueue(id, space)

        expect(q.next_fitting_in(space)).to eq([id, space])
      end

      it 'returns the only available one for a bit less space' do
        id = 10

        q.enqueue(id, 1)

        expect(q.next_fitting_in(2)).to eq([id, 1])
      end

      it 'returns the first when two of same space' do
        space = 5

        q.enqueue(1, space)
        q.enqueue(2, space)

        expect(q.next_fitting_in(space)).to eq([1, space])
      end

      it 'returns the second when the first does not fit' do
        q.enqueue(1, 5)
        q.enqueue(2, 4)

        expect(q.next_fitting_in(4)).to eq([2, 4])
      end

      it 'returns the first when can fit less than second' do
        q.enqueue(2, 4)
        q.enqueue(1, 5)

        expect(q.next_fitting_in(5)).to eq([2, 4])
      end

      it 'returns nil when cannot find space' do
        q.enqueue(1, 5)
        q.enqueue(2, 6)
        q.enqueue(3, 3)

        expect(q.next_fitting_in(2)).to eq(nil)
      end
    end
  end
end
