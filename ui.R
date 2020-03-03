shinyUI(fluidPage(
  
  # Window title:
  list(tags$head(HTML('<link rel="icon", href="SOLVE LABS_ICON_MONO_B@2x.png", type="image/png" />'))),
  titlePanel(title="", windowTitle="MICA - Solve Geosolutions"),
  
  # theme/tags:
  theme = shinytheme("flatly"),
  tags$head(tags$style("#minPlot{height:80vh !important;}")),
  tags$head(tags$style("#confusion_plot{height:70vh !important;}")),
  tags$head(tags$style("#clusterTile{height:115vh !important;}")),
  tags$head(tags$script(type="text/javascript", src = "right_image.js")),
  
  # offset body due to fixed-top
  tags$style(type="text/css", "body {padding-top: 60px;}"),
  
  # Welcome modal:
  use_ModalInUI(),
  
  modalInUI(id = 'welcome', title = h2("Welcome to MICA!", align='center'),
            img(src="SOLVE LABS_ICON_TEXT_STACKED_B.svg", height="400",
                onclick ="window.open('http://www.solvegeosolutions.com/', '_blank')",
                style="display: block; margin-left: auto; margin-right: auto;"),
            br(),
            p('Hi! Use MICA to perform Mineral Identification and Compositional Analysis!', align='center'),
            p('Click the logo ',  a(href="http://www.solvegeosolutions.com/", target='_blank', "or here"), ' to go to our website. ', a(href="mailto:info@solvegeosolutions.com", "Click here to email us!"), align='center'),
            br(),
            
            actionButton('closeWelcome', 'Let\'s go', width='100%')
  ),
  
  sidebarLayout(
    
    sidebarPanel(width=5,
                 
                 navbarPage(div(img(src="MICA.png",
                                    height="50",
                                    onclick ="window.open('http://www.solvegeosolutions.com/', '_blank')"),
                                style = "position: relative; left: 0%; top: -70%"),
                            id = 'sidepanel',
                            position = "fixed-top",
                            
                            tabPanel("Confusion",
                                     fluidRow(
                                       column(width=6,
                                              pickerInput(inputId = 'confusionMin',
                                                          label = 'Mineral to compare:',
                                                          choices = c(Choose='', minerals_names),
                                                          selected = "Cummingtonite",
                                                          multiple=F,
                                                          options = pickerOptions(actionsBox = T,
                                                                                  size = 10,
                                                                                  liveSearch = T))),
                                       column(width=6,
                                              numericInput(inputId = 'confusion_N',
                                                           label = 'Number of confusing minerals',
                                                           value = 5,
                                                           max = 10))
                                     ),
                                     
                                     withSpinner(plotlyOutput('confusion_plot'))
                                     
                            ),
                            
                            tabPanel("Minerals",
                                     
                                     p('Minerals in selected cluster (click to choose a new mineral to compare):'),
                                     column(width=12,
                                            style = "overflow-y:scroll; max-height: 75vh",
                                            withSpinner(dataTableOutput("sel_min_tab"))
                                     )
                                     
                            ),
                            
                            tabPanel("Elements",
                                     
                                     p('Unsupervised element importance for selected cluster:'),
                                     column(width=12,
                                            style = "overflow-y:scroll; max-height: 75vh",
                                            withSpinner(dataTableOutput("var_imp_tab"))
                                     )
                                     
                            ),
                            
                            tabPanel("Clusters",
                                     p("Mean value of each element for each clusters. Click to go to a cluster."),
                                     plotlyOutput("clusterTile")
                            ),
                            

                            tabPanel("Help",
                                     tabsetPanel(id='helpPanel',

                                                  # tabPanel("Introduction",
                                                  #          uiOutput('help_intro')
                                                  # ),
                                                  tabPanel("What is it?",
                                                           uiOutput('help_what')
                                                  ),
                                                  tabPanel("How do I use it?",
                                                           uiOutput('help_use')
                                                  )
                                     )
                            )
                            
                            
                            
                            
                 )
                 
    ),
    mainPanel(width=7,
              
              fluidRow(
                column(width=6,
                       selectInput(inputId = 'element',
                                   label = 'Element to colour by',
                                   choices = c('Cluster', element_names),
                                   selected = 'Cluster',
                                   width='100%')),
                column(width=6,
                       selectInput(inputId = 'elementSize',
                                   label = 'Element to size by',
                                   choices = element_names,
                                   selected = 'Sulfur',
                                   width='100%'))
              ),
              
              plotlyOutput("minPlot")
              
    )
  )
  
))
