function changeSubscribeButtons(new_text, new_class_name) {
  // test environment
  if (!document.getElementsByClassName) return false;
  if (!document.getElementsByTagName) return false;
  if (!document.getElementsByClassName("subscribe-button-form")) return false;

  var subscribe_forms = document.getElementsByClassName("subscribe-button-form");

  for (var i = 0 ; i < subscribe_forms.length ; i++) {
    // make sure there is only one button
    if (subscribe_forms[i].getElementsByTagName("button").length !== 1) return false;
    var button = subscribe_forms[i].getElementsByTagName("button")[0];

    // check that the last child of the button is a text node
    if (button.lastChild.nodeType !== 3) return false;
    var copy = button.lastChild;

    // capture the orginal text
    var original_text = copy.nodeValue;

    // change the button text
    copy.nodeValue = new_text;

    // change the text value

    // add a class name to the form
    subscribe_forms[i].className += " " + new_class_name;

    // swap back on hover
    button.onmouseover = function() {
      copy.nodeValue = original_text;
    };

    button.onmouseout = function() {
      copy.nodeValue = new_text;
    };
  }
}
