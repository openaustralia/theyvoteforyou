<pre>GET <%= link_to api_v1_divisions_url(format: "json"), api_v1_divisions_url(format: "json") %></pre>

This returns basic information about the **most recent 100** divisions including

Parameter          | Description
------------------ | -----------------------------------------------------------
`id`               | A unique identifier for this division. Use the `id` to get more information about this division
`house`            | Whether this division took place in the House of Representatives or the Senate
`name`             | Short name
`date`             | Date in the format `yyyy-mm-dd`
`number`           | The first division on a particular day and in a particular house is 1. Each following division is numbered consecutively
`clock_time`       | The time of the division in the format `hh:mm AM` or `hh:mm PM` or `null` if not available
`aye_votes`        | The number of people who voted "aye"
`no_votes`         | The number of people who voted "no"
`possible_turnout` | The number of people who could potentially have voted based on the current number of members
`rebellions`       | The number of votes that went against the majority vote of their party
`edited`           | `true` if the summary of the division has been edited

To get more results or divisions within a particular date range you can do

<pre>GET <%= link_to api_v1_divisions_url(format: "json", start_date: "2014-08-01", end_date: "2014-09-01", house: "senate"), api_v1_divisions_url(format: "json", start_date: "2014-08-01", end_date: "2014-09-01", house: "senate") %></pre>

Again this will return **at most 100** results. It is your responsibility to ensure that you are
getting all the data you expect. In practise if you receive 100 results narrow the date range or just look
at the specific house you are interested in.
