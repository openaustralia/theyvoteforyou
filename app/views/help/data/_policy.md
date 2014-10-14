<pre>GET <%= api_v1_policy_url(format: "json", id: "foo").gsub("foo", "[id]") %></pre>

For example

<pre>GET <%= link_to api_v1_policy_url(format: "json", id: 1), api_v1_policy_url(format: "json", id: 1) %></pre>

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
      <td><code>id</code></td>
      <td>A unique identifier for this division. Use the <code>id</code> to get more information about this policy</td>
    </tr>
    <tr>
      <td><code>name</code></td>
      <td>A short name for the policy</td>
    </tr>
    <tr>
      <td><code>description</code></td>
      <td>More detail on what the policy means</td>
    </tr>
    <tr>
      <td><code>provisional</code></td>
      <td><code>true</code> or <code>false</code>. A provisional policy isn't yet "complete" and isn't visible by default in comparisons with people</td>
    </tr>
    <tr>
      <td><code>policy_divisions</code></td>
      <td>An array of divisions connected to this policy. Each division also has an associated <code>vote</code> which can be <code>strong</code> which makes the vote more important</td>
    </tr>
    <tr>
      <td><code>people_comparisons</code></td>
      <td>An array of people who could have voted on this division and their calculated <code>agreement</code>
      score in range from 0 to 100. <code>voted</code> says whether they ever vote on a division from this policy.</td></td>
    </tr>
  </tbody>
</table>
