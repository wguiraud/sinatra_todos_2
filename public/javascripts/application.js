$(function() { 
  
  $("form.delete").submit(function(even) { 
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? this cannot be undone!"); 
    if (ok) { 
      this.submit();
    }

  });

}); 
