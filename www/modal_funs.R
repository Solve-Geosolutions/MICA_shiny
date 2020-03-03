# custom modal functions
use_ModalInUI <- function(){
  tagList(
    tags$script("Shiny.addCustomMessageHandler('launch-modal', function(d) {$('#' + d).modal().focus();})"),
    tags$script("Shiny.addCustomMessageHandler('remove-modal', function(d) {$('#' + d).modal('hide');})")
  )
}

# The UI element
modalInUI <- function(id = 'my-modal', title = 'Title', ...){
  
  tags$div(
    id = id,
    class="modal fade", tabindex="-1", `data-backdrop`="static", `data-keyboard`="false",
    tags$div(
      class="modal-dialog",
      tags$div(
        class = "modal-content",
        tags$div(class="modal-header", tags$h4(class="modal-title", title)),
        tags$div(
          class="modal-body",
          ...
        )
      )
    )
  )
  
}

# Open the modal
open_modalInUI <- function(id, session){
  session$sendCustomMessage(type = 'launch-modal', id)
}

# Close the modal
close_modalInUI <- function(id, session){
  session$sendCustomMessage(type = 'remove-modal', id)
}