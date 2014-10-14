<pre>GET <%= link_to api_v1_policies_url(format: "json"), api_v1_policies_url(format: "json") %></pre>

This returns basic information about policies including

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
  </tbody>
</table>
