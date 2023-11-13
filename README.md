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

## Usage

I've added some scripts for easier development

### Local scripts

- `start-api` to run it locally and used within docker. This can receive
   an optional `PORT` environment variable: `PORT=9091 ./start-api`
- `run-tests` to run the tests locally and used within docker.

### Docker scripts

- `docker-build-api` to build the container
- `docker-start-api` to run the previously built container. This can receive
   an optional `PORT` environment variable: `PORT=9091 ./docker-start-api`.
   If not specified, the `Dockerfile` defaults to port 9091.
- `docker-stop-api` to stop all the API running containers
- `docker-run-tests` to run the tests inside the previously built container.
