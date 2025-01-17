# Car Pooling Service Challenge

Design/implement a system to manage car pooling.

We provide the service of taking people from point A to point B.
So far we have done it without sharing cars with multiple groups of people.
This is an opportunity to optimize the use of resources by introducing car
pooling.

You have been assigned to build the car availability service that will be used
to track the available seats in cars.

Cars have a different amount of seats available, they can accommodate groups of
up to 4, 5 or 6 people.

People requests cars in groups of 1 to 6. People in the same group want to ride
on the same car. You can take any group at any car that has enough empty seats
for them. If it's not possible to accommodate them, they're willing to wait until 
there's a car available for them. Once a car is available for a group
that is waiting, they should ride. 

Once they get a car assigned, they will journey until the drop off, you cannot
ask them to take another car (i.e. you cannot swap them to another car to
make space for another group).

In terms of fairness of trip order: groups should be served as fast as possible,
but the arrival order should be kept when possible.
If group B arrives later than group A, it can only be served before group A
if no car can serve group A.

For example: a group of 6 is waiting for a car and there are 4 empty seats at
a car for 6; if a group of 2 requests a car you may take them in the car.
This may mean that the group of 6 waits a long time,
possibly until they become frustrated and leave.

## Evaluation rules

This challenge has a partially automated scoring system. This means that before
it is seen by the evaluators, it needs to pass a series of automated checks
and scoring.

### Checks

All checks need to pass in order for the challenge to be reviewed.

- The `acceptance` test step must pass in master before you
submit your solution. We will not accept any solutions that do not pass or omit
this step. This is a public check that can be used to assert that other tests 
will run successfully on your solution. **This step needs to run without 
modification**
- _"further tests"_ will be used to prove that the solution works correctly. 
These are not visible to you as a candidate and will be run once you submit 
the solution

### Scoring

There is a number of scoring systems being run on your solution after it is 
submitted. It is ok if these do not pass, but they add information for the
reviewers.

## API

To simplify the challenge and remove language restrictions, this service must
provide a REST API which will be used to interact with it.

This API must comply with the following contract:

### GET /status

Indicate the service has started up correctly and is ready to accept requests.

Responses:

* **200 OK** When the service is ready to receive requests.

### PUT /cars

Load the list of available cars in the service and remove all previous data
(reset the application state). This method may be called more than once during
the life cycle of the service.

**Body** _required_ The list of cars to load.

**Content Type** `application/json`

Sample:

```json
[
  {
    "id": 1,
    "seats": 4
  },
  {
    "id": 2,
    "seats": 6
  }
]
```

Responses:

* **200 OK** When the list is registered correctly.
* **400 Bad Request** When there is a failure in the request format, expected
  headers, or the payload can't be unmarshalled.

### POST /journey

A group of people requests to perform a journey.

**Body** _required_ The group of people that wants to perform the journey

**Content Type** `application/json`

Sample:

```json
{
  "id": 1,
  "people": 4
}
```

Responses:

* **200 OK** or **202 Accepted** When the group is registered correctly
* **400 Bad Request** When there is a failure in the request format or the
  payload can't be unmarshalled.

### POST /dropoff

A group of people requests to be dropped off. Whether they traveled or not.

**Body** _required_ A form with the group ID, such that `ID=X`

**Content Type** `application/x-www-form-urlencoded`

Responses:

* **200 OK** or **204 No Content** When the group is unregistered correctly.
* **404 Not Found** When the group is not to be found.
* **400 Bad Request** When there is a failure in the request format or the
  payload can't be unmarshalled.

### POST /locate

Given a group ID such that `ID=X`, return the car the group is traveling
with, or no car if they are still waiting to be served.

**Body** _required_ A url encoded form with the group ID such that `ID=X`

**Content Type** `application/x-www-form-urlencoded`

**Accept** `application/json`

Responses:

* **200 OK** With the car as the payload when the group is assigned to a car. See below for the expected car representation 
```json
  {
    "id": 1,
    "seats": 4
  }
```

* **204 No Content** When the group is waiting to be assigned to a car.
* **404 Not Found** When the group is not to be found.
* **400 Bad Request** When there is a failure in the request format or the
  payload can't be unmarshalled.

## Tooling

We use CI for our backend development work. 
Note that the image build should be reproducible within the CI environment.

Additionally, you will find a basic Dockerfile which you could use a
baseline, be sure to modify it as much as needed, but keep the exposed port
as is to simplify the testing.

:warning: Avoid dependencies and tools that would require changes to the 
`acceptance` step, such as `docker-compose`

:warning: The challenge needs to be self-contained so we can evaluate it. 
If the language you are using has limitations that block you from solving this 
challenge without using a database, please document your reasoning in the 
readme and use an embedded one such as sqlite.

You are free to use whatever programming language you deem is best to solve the
problem but please bear in mind we want to see your best!

## Requirements

- The service should be as efficient as possible.
  It should be able to work reasonably well with at least $`10^4`$ / $`10^5`$ cars / waiting groups.
  Explain how you did achieve this requirement.
- You are free to modify the repository as much as necessary to include or remove
  dependencies, subject to tooling limitations above.
- Document your decisions using MRs or in this very README adding sections to it,
  the same way you would be generating documentation for any other deliverable.
  We want to see how you operate in a quasi real work environment.

# Solution

## Decision log

### Ruby+Rack+Puma

I've decided to start with Ruby as it is one of the skills you're looking for, 
I have enough experience with it and it might be good enough for the requirements.
I'll use Rack as the web framework because it is very lightweight and it is the 
basis for Ruby on Rails. For the web server, I'll use Puma as it has worked well
for me in the past. (I'll need to verify the most demanding scenarios once it is
solved to see if it bottlenecks somewhere).

### In-memory storage

Given the :warning: warning about the solution needing to be self-contained
without using a database (in the [Tooling section](#tooling)),
I'm assuming persistence of the data across restarts of the service is not desired.
For now, I'm going to start with an in-memory data storage for this reason.
I'm guessing an in-memory storage for 10^5 cars and waiting groups might end up
using 8 - 32 GB or RAM memory which might be viable.
Will revisit the in-memory approach once I verify this assumption.

Revisit: After asking this, reiterating the instructions on this
readme. Which led me to continue with those assumptions.
In his words: "Sorry for not being more explicit, but one of the points of the exercise
is to understand the current requirements. If you think something has not been explained
correctly, you can make your own decision, documenting and justifying your assumption."

### Unclear aspects

On further thinking and development of the solution, some unclear aspects became
apparent:

- What happens for duplicate `id`s?
  - On `PUT /cars`, two car objects in the list from the json body have the same `id`
    value. In this case, I've decided to respond a `400 Bad Request`.
  - On `POST /journey`, a second request with the same `id` value without requesting
    `POST /dropoff` in between.
    In this case, I've decided to respond a `409 Conflict`.

- Which car to choose when multiple suitable cars are available?
  - The description mentions "any car" can be taken. I've decided to prefer the ones
    that would be filled the most with the group. This decision intends to better
    "optimize the use of resources" (mentioned in the description as the goal).

- What happens on `POST /locate` after a `POST /dropoff` for the same `id` if it was
  previously assigned to a car?
  - I'm guessing responding `404 Not Found` with empty body is the expected behavior.
    But responding `404 Not Found` with the previously assigned car in the body might
    be also desired. I've decided to keep the body empty.

- Given the description mentions "the car availability service that will be used to
  track the available seats in cars" makes me think there are at least two
  interpretations of what the `seats` attribute for the car object in the `POST /locate`
  endpoint can be intended to be:
  - The same amount of seats for that car id specified on `PUT /cars`. I've decided
    to go for this one.
  - The amount of available seats or used seats in the car.

- The `POST /locate` endpoint would also make sense if defined with the `GET` method
  instead of `POST` and the `id` as a query parameter. This is just an observation.

- Not allowing to add or remove cars in any other way but with `PUT /cars` makes me
  guess this is to simplify the challenge. In a real situation, I would expect cars
  to become and stop being available independently of the rest of the cars. This is
  just an observation.

### Git history / MRs / README documentation

I've decided to keep as raw as possible the history of commits for transparency sake.

In the context where there needs to be collaboration with other teammates between
changes, the MRs would be a great tool to use for allowing feedback loops.
In a solo development context, I think it loses a lot of value (the feedback loop with
other people's perspectives).
I've decided to focus on the technical aspects and leave the documentation / sharing
details to this README.

At the end, after getting the acceptance tests passing, I've tried to keep pushes to
master as if it was a branch intended to be stable
(passing tests and worthy changes before pushing).

## Additional tests

I've added tests during development for increasing the chances that the code works as
well as expected.

All of them using RSpec and other libraries. They are located inside the `spec` folder.

Check the [Usage section](#usage) for more details on how to run them.

I've used 3 kinds of tests:

### Unit tests

For checking the expected behavior of the parts by using specific examples of situations.

### Property tests

For checking the expected behavior for the `WaitingQueue` and as an applicable showcase
for the property-based testing approach, although Ruby is not the best language for it.

This example uses a `SimplerQueue` as a reference of the correct behavior and checks
that: for many sets of random valid actions and arguments, they behave in the same way.

In this case, this is useful because `WaitingQueue` has been implemented trying to be
more efficient (and consequently more complex) than `SimplerQueue` but can be
interchangeable and should keep the same correct behavior.

### Performance tests

For measuring how long or how much memory certain parts of the code take.
Their files are terminated with `*_performance_spec.rb` and are filtered by the tag
`performance`.

For example (and in reference to the previous `property tests`), there are performance
tests comparing the time cost for `WaitingQueue` vs the `SimplerQueue` for 10^6 groups.

The end-to-end business logic (on `CarPooling::Service`) performance tests are measuring
the time cost and memory usage for 10^3, 10^4, 10^5 and 10^6 cars and groups in the
different actions (load cars, add journey, dropoff and locate).

This last one also includes a profiler run to see where there might be performance
bottlenecks.

## Optimizations

Since one of the points in the [Requirements section](#requirements) is "The service
should be as efficient as possible. ... Explain how you did achieve this requirement.",
I'm going to use this section and subsections to explain the details of the approach
and results.

I initially implemented a naive solution to see the acceptance tests passing. This
initial solution was not prioritized to be performant.

On focusing in optimizing the performance, I've prioritized a better time cost over
memory usage but still tried to minimize it when possible.

After several drafts for the actions and data involved, I identified two distinct
contexts: managing the car spaces (`class CarSpace`) and the waiting queue (`class 
WaitingQueue`). And decided to optimize them independently.

All the optimizations are based on two relationships (implemented with dictionaries):
- direct access to the related data from the id
  - seats for a car id
  - people for a group id
- we can filter out a lot by starting from
  - the amount of available seats for cars
  - the amount of people for waiting groups

### `CarSpace`

Here, when loading the cars, the car ids are grouped by their available seats using a
dictionary whose keys are the available seats and values are `Set`s for the car ids.

This allows to find quickly the cars with closest available seats for the people in the
group: O(1).

Updating the available seats is less efficient as I believe inserting in the `Set` might
be O(n). `n` here being the amount of cars with the same available seats.

I believe this could be optimized further by using a binary tree instead: O(log n).

Just realized this while writing this documentation.

### `WaitingQueue`

`Hash` in Ruby preserves the order of key insertion, so I'm using the keys for the group
id so it is efficient to enqueue: O(1) and to drop off: O(1).

The queue is traversed when a group has dropped off from a car. At that point we know how
many seats are available in that car, and we cannot fit groups bigger than that.
Traversing the whole queue skipping the ones that do not fit would be O(n).

So, having a queue that only traverses the groups who can fit (of the available space or below)
allows us to take the first one immediately. Having cost O(1).

Since there are only 6 possible amounts of people, we can achieve this by keeping 6 versions
of the queue. One for each possible amount of people. We just need to enqueue: O(1) and
drop off: O(1) from all at the same time.

If adding to the queue a group with > 6 people (not expected), the queue for all the groups
(<= 6 people) would need to be cloned. Having cost O(n). Subsequent enqueue calls for groups
of the same amount of people would be O(1).

## Performance measurements summary

These results are taken from running the [performance tests](#performance_tests)

- load cars: time O(n), memory O(n)
- journey: time O(1)
- dropoff: time O(1)
- locate:  time O(1)

### Time measurements

Time values are in seconds

| random seats | 10^3     | 10^4     | 10^5     | 10^6     |
|--------------|----------|----------|----------|----------|
| load cars    | 0.000296 | 0.002673 | 0.028729 | 0.327764 |

| same seats   | 10^3     | 10^4     | 10^5     | 10^6     |
|--------------|----------|----------|----------|----------|
| load cars    | 0.000275 | 0.002586 | 0.027652 | 0.321103 |

CAVEAT: these measurements do not include the API parsing the cars JSON into a Hash id => seats

| groups random people | 10^3     | 10^4     | 10^5     | 10^6     |
|----------------------|----------|----------|----------|----------|
| journey              | 0.000019 | 0.000019 | 0.000024 | 0.000030 |
| dropoff              | 0.000016 | 0.000018 | 0.000023 | 0.000029 |
| locate               | 0.000010 | 0.000010 | 0.000013 | 0.000014 |

| cars random seats | 10^3     | 10^4     | 10^5     | 10^6     |
|-------------------|----------|----------|----------|----------|
| journey           | 0.000023 | 0.000025 | 0.000031 | 0.000026 |
| dropoff           | 0.000021 | 0.000022 | 0.000031 | 0.000026 |
| locate            | 0.000013 | 0.000011 | 0.000015 | 0.000014 |

| cars and groups random | 10^3     | 10^4     | 10^5     | 10^6     |
|------------------------|----------|----------|----------|----------|
| journey                | 0.000024 | 0.000024 | 0.000030 | 0.000038 |
| dropoff                | 0.000023 | 0.000021 | 0.000030 | 0.000035 |
| locate                 | 0.000011 | 0.000013 | 0.000017 | 0.000019 |

### Memory measurements

| load cars memory       | 10^3     | 10^4     | 10^5    | 10^6     |
|------------------------|----------|----------|---------|----------|
| cars and groups random | 457.720k | 4.909M   | 52.530M | 478.723M |
| cars random            | 73.000k  | 804.136k | 10.487M | 83.887M  |
| groups random          | 325.984k | 3.608M   | 37.890M | 336.162M |

CAVEAT: these measurements do not include the API parsing the cars JSON into a Hash id => seats

## Usage

I've added some scripts for easier development

### Local scripts

- `start-api` to run it locally and used within docker. This can receive
   an optional `PORT` environment variable: `PORT=9091 ./start-api`.
- `run-tests` to run the behavior tests locally and used within docker.
- `run-performance-tests` to run the performance measurements and used within docker.

### Docker scripts

- `docker-build-api` to build the container.
- `docker-start-api` to run the previously built container. This can receive
   an optional `PORT` environment variable: `PORT=9091 ./docker-start-api`.
   If not specified, the `Dockerfile` defaults to port 9091.
- `docker-stop-api` to stop all the API running containers.
- `docker-run-tests` to run the behavior tests inside the previously built container.
- `docker-run-performance-tests` to run the performance measurements inside the previously
  built container.
