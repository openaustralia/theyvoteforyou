<pre>GET <%= api_v1_person_url(format: "json", id: "foo").gsub("foo", "[id]") %></pre>

For example

<pre>GET <%= link_to api_v1_person_url(format: "json", id: 10001), api_v1_person_url(format: "json", id: 10001) %></pre>

This returns all sorts of useful detailed information, including

<table class="table">
  <thead>
    <tr>
      <th>Parameter</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>rebellions</code></td>
      <td>The number of times they have rebelled against their party</td>
    </tr>
    <tr>
      <td><code>votes_attended</code></td>
      <td>The number of divisions in which they have voted</td>
    </tr>
    <tr>
      <td><code>votes_possible</code></td>
      <td>The number of possible divisions they could have voted in</td>
    </tr>
    <tr>
      <td><code>offices</code></td>
      <td>An array of current ministerial (or shadow ministerial) positions</td>
    </tr>
    <tr>
      <td><code>policy_comparisons</code></td>
      <td>An array of policies that this person could have voted on and their calculated <code>agreement</code>
      score in range from 0 to 100. <code>voted</code> says whether they ever vote on a division from this policy.</td>
    </tr>
  </tbody>
</table>
