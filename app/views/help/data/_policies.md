<pre>GET <%= link_to api_v1_policies_url(format: "json"), api_v1_policies_url(format: "json") %></pre>

This returns basic information about policies including

Parameter     | Description
------------- | -----------------------------------------------------------
`id`          | A unique identifier for this division. Use the `id` to get more information about this policy
`name`        | A short name for the policy
`description` | More detail on what the policy means
`provisional` | `true` or `false`. A provisional policy isn't yet "complete" and isn't visible by default in comparisons with people
