<% if current_user %>
<pre>GET <%= link_to api_v1_policies_url(format: "json", key: current_user.api_key), api_v1_policies_url(format: "json", key: current_user.api_key) %></pre>
<% else %>
<pre>GET <%= api_v1_policies_url(format: "json", key: "api_key2").gsub("api_key2", "[api_key]") %></pre>
<% end %>

This returns basic information about policies including

Parameter     | Description
------------- | -----------------------------------------------------------
`id`          | A unique identifier for this policy. Use the `id` to get more information about this policy
`name`        | A short name for the policy
`description` | More detail on what the policy means
`provisional` | `true` or `false`. A provisional policy isn't yet "complete" and isn't visible by default in comparisons with people
