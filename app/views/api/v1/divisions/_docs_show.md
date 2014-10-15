<pre>GET <%= api_v1_division_url(format: "json", id: "foo").gsub("foo", "[id]") %></pre>

For example

<pre>GET <%= link_to api_v1_division_url(format: "json", id: 2788), api_v1_division_url(format: "json", id: 2788) %></pre>

This returns all sorts of useful detailed information, including

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
`summary`          | If `edited` is `false` this is a bit of text from the Hansard near to where the division took place. If `edited` is `true` then this is the latest version of the summary text written by contributors. It is formatted in Markdown.
`votes`            | An array of the votes cast by the members in this division
`policy_divisions` | An array of policies that are connected to this division including how they voted
`bills`            | An array of bills connected to this division
