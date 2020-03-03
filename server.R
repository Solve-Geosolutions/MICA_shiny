shinyServer(function(input, output, session) {
  
  rv <- reactiveValues()
  
  # initial welcome modal
  open_modalInUI(id = 'welcome', session = session)
  
  # close welcome modal
  observeEvent(input$closeWelcome, {
    close_modalInUI(id = 'welcome', session = session)
  })
  
  # the main mineral plot
  output$minPlot <- renderPlotly({
    
    # set up colour palettes for points
    if(input$element == 'Cluster'){
      colplt <- factor(df[,'Cluster'])
      col2 <- NULL
    } else {
      colplt <- as.numeric(df[,input$element])
      col2 <- colorRamp(c("blue","red"))
    }
    
    # remove visible axes
    ax <- list(
      title = "",
      zeroline = FALSE,
      showline = FALSE,
      showticklabels = FALSE,
      showgrid = FALSE
    )
    
    plot_ly(
      type = 'scatter3d',
      mode = 'markers',
      source = 'main',
      x = as.numeric(df$x),
      y = as.numeric(df$y),
      z = as.numeric(df$z),
      color = colplt,
      colors = col2,
      size = as.numeric(df[, input$elementSize]),
      sizes = c(5, 400),
      marker = list(opacity=0.5),
      text = paste0("Mineral:", df$Mineral, "<br>", 
                   "Cluster:", df$Cluster),
      hoverinfo = 'text') %>%
      
      hide_colorbar() %>%
      hide_legend() %>%
      
      config(displaylogo = FALSE, displayModeBar = T) %>%
      
      layout(
        scene=list(xaxis = ax,
                   yaxis = ax,
                   zaxis = ax))
    
  })

  # variable importance table
  output$var_imp_tab <- renderDataTable({
    
    req(rv$varImportance)
    datatable(data = rv$varImportance,
              selection = 'single',
              options = list(pageLength = nrow(rv$varImportance),
                             searching = F,
                             lengthChange = F,
                             paging = F))
  })
  
  # minerals in selected cluster table
  output$sel_min_tab <- renderDataTable({
    
    req(rv$selected_mins)
    datatable(rv$selected_mins,
              selection = 'single',
              options = list(pageLength = nrow(rv$selected_mins),
                             searching = F,
                             lengthChange = F,
                             paging = F))
  })
  
  observeEvent(input$sel_min_tab_rows_selected, {
    updateSelectInput(session,
                      inputId = 'confusionMin',
                      selected = rv$selected_mins$Mineral[input$sel_min_tab_rows_selected])
    updateNavbarPage(session, inputId = 'sidepanel', selected = 'Confusion')
  })
  

  # Find mineral that is clicked on from 3D UMAP
  observeEvent(event_data("plotly_click", source = 'main'), {
    
    d <- event_data("plotly_click", source = 'main')
    req(d)
    
    # get the mineral that was clicked:
    if(input$element == "Cluster"){
      clicked_min <- 
        df %>%
        filter(Cluster == d$curveNumber) %>% 
        slice(d$pointNumber+1) %>% 
        .$Mineral
    } else {
      clicked_min <- 
        df %>%
        slice(d$pointNumber+1) %>% 
        .$Mineral
    }
    
    updateSelectInput(session, 'confusionMin', selected = clicked_min)
    
  })
  
  # when the mineral to compare or the number to compare with change:
  observeEvent({
    input$confusionMin
    input$confusion_N
  }, {
    
    req(isTruthy(input$confusionMin),
        input$confusion_N > 0)
    
    # find cluster that clicked mineral belongs to
    selectedCluster <-
      df %>% 
      filter(Mineral == input$confusionMin) %>% 
      .$Cluster
    
    # get composition of all minerals in the selected cluster
    df_toRF <-
      df %>%
      filter(Cluster == selectedCluster) %>% 
      dplyr::select(-Mineral, -ChemFormula, -x, -y, -z, -Cluster)
    
    # unsupervised RF to get unsupervised feature importance
    withProgress({
      rf <- randomForest(x = df_toRF,
                         proximity=TRUE)
    }, value = 0.3, message = "Please wait", detail = "Getting feature importance")
    
    rf_out <<- rf
    
    # get data.frame of the ranked feature importance
    rv$varImportance <-
      rf$importance %>% 
      as.data.frame() %>%
      rownames_to_column(var = 'Element') %>%
      arrange(desc(MeanDecreaseGini)) %>%
      mutate(MeanDecreaseGini = round(MeanDecreaseGini, 3)) %>%
      filter(MeanDecreaseGini > 0)
    
    # data.frame of minerals in selected cluster
    rv$selected_mins <-
      df %>%
      filter(Cluster == selectedCluster) %>%
      dplyr::select(Mineral, ChemFormula)
    
    
    
    # find closest minerals to the selected one:
    df_umap_positions <-
      df %>%
      filter(Mineral == input$confusionMin) %>%
      select(x, y, z)
    
    nns <- knn(data = df %>% dplyr::select(x, y, z),
               query = df_umap_positions,
               k = input$confusion_N + 1)
    
    close_mins <- as.character(df$Mineral[as.integer(nns$nn.idx)])
    close_dist <- as.numeric(nns$nn.dists)
    
    close_df <- data.frame(Mineral = close_mins,
                           Dist = close_dist)
    
    df_compare <- 
      df %>%
      filter(Mineral %in% c(input$confusionMin, close_mins)) %>%
      select(-c(ChemFormula, x, y, z)) %>%
      left_join(close_df,
                by = "Mineral") %>%
      arrange(Dist)
    
    df_compare <- df_compare[, colSums(df_compare != 0) > 0]
    
    rv$df_plot <-
      df_compare %>%
      gather('Element', 'Percent', -c(Mineral, Dist, Cluster)) %>%
      arrange(Dist) %>%
      mutate(Mineral = factor(Mineral, levels = close_mins))
    
    
  })
  
  # plot of the composition of N most similar minerals
  output$confusion_plot <- renderPlotly({
    
    req(isTruthy(rv$df_plot))
      
      ggplot(rv$df_plot, aes(x = Mineral, y = Percent)) +
        geom_bar(aes(fill=Element), col='black', stat='identity') +
        theme(axis.text.x = element_text(angle = 90, hjust = 1))
      
      ggplotly() %>%
        config(displayModeBar = F)

  })
  
  # the geom_tile plot of mean cluster composition of elements
  output$clusterTile <- renderPlotly({
    
    # statistics of elements in each cluster:
    df_stats <-
      df %>%
      dplyr::select(-Mineral, -ChemFormula, -x, -y, -z) %>%
      group_by(Cluster) %>%
      summarise_all(mean)
    
    # tile plot of distribution of each cluster
    cluster_stat_plt <-
      df_stats %>%
      gather('Element', 'Percent', -Cluster) %>%
      mutate(Percent = round(Percent, 3)) %>% 
      ggplot(aes(Cluster, Element, fill = Percent)) +
      geom_tile() +
      scale_fill_viridis_c(option = 'plasma', guide = F)
    
    # Interactive plotly version of this plot
    ggplotly(cluster_stat_plt, source = "clusterPlot") %>%
      layout(xaxis = list(tickangle = 90)) %>%
      config(displayModeBar = F) %>% 
      event_register(event = 'plotly_click')
  })
  
  observeEvent(event_data("plotly_click", source = 'clusterPlot'), {
    
    clicked_cluster <- event_data("plotly_click", source = 'clusterPlot')$x
    
    # find the first mineral in that cluster:
    min_to_update <-
      df %>%
      filter(Cluster == clicked_cluster) %>% 
      slice(1) %>% 
      .$Mineral
    
    updateSelectInput(session, 'confusionMin', selected = as.character(min_to_update))
    updateNavbarPage(session, inputId = 'sidepanel', selected = 'Minerals')
    
    
  })

  
  # HELP ####
  # output$help_intro <- renderUI({
  #   includeMarkdown('www/introduction.md')
  # })
  output$help_what <- renderUI({
    includeMarkdown('www/whatIsMICA.md')
  })
  output$help_use <- renderUI({
    includeMarkdown('www/howUseMICA.md')
  })
  
})