rdirichlet <- function(n, alpha) {
  normalize <- function(.) . / sum(.)
  samps <- vapply(alpha, function(al) stats::rgamma(n, al, 1), numeric(n))
  if(class(samps) == "matrix" ){ ret_q <- t(apply(samps, 1, normalize)) }
  if(class(samps) == "numeric" ){ ret_q <- normalize(samps) }
  return( ret_q ) 
}


firat2018 <- function(csv_category_, INPUT_labeled_sz, INPUT_unlabeled_sz){ 
  labeled_indices <- sample(1:length(csv_category_), INPUT_labeled_sz)
  labeled_pd <- prop.table(table(csv_category_[labeled_indices]))
  n_cat <- length(labeled_pd)
  if(n_cat >= 8){ 
    pos <- rdirichlet(2,alpha = rep(1, times = n_cat))
  }
  
  if(n_cat < 8){
    eval(parse(text = sprintf("x <- expand.grid(%s)", paste(rep("seq(0,1,0.1)", n_cat), collapse = ","))))
    pos<-x[which(round(rowSums(x),1)==1.0),]
  }
  target_unlabeled_pd <- pos[sample(1:nrow(pos),1),]
  unlabeled_pd_by_n <- round(INPUT_unlabeled_sz*target_unlabeled_pd)
  
  indices_list <- tapply(1:length(csv_category_), csv_category_, c)
  indices_list <- indices_list[names(labeled_pd)]
  unlabeled_indices <- unlist( sapply(1:length(indices_list), function(x){
        sample( indices_list[[x]], min(unlabeled_pd_by_n[x], length(indices_list[[x]])), replace = F ) }) ) 
  return(list(labeled_indices=labeled_indices,
              unlabeled_indices=unlabeled_indices))
} 


historical_fxn <- function(INPUT_CAT , INPUT_labeled_sz = 100, INPUT_unlabeled_sz = 100){ 
  ## Get all indices
  all_indices <- 1:length(INPUT_CAT)
  
  ## Pick a random starting index for the labeled set
  start_index <- sample(1:length(all_indices), 1)
  
  ## Calculate labeled_indices
  ## no overflow
  if (start_index + INPUT_labeled_sz - 1 <= length(all_indices)){
    labeled_indices <- all_indices[start_index:(start_index + INPUT_labeled_sz - 1)]
    
  }else{ #overflow
    ## First part of labeled indices
    labeled_indices <- all_indices[start_index:length(all_indices)]
    ## Calculate remaining needed
    remaining_sample <- INPUT_labeled_sz - length(labeled_indices)
    ## Add from the beginning
    labeled_indices <- c(labeled_indices, all_indices[1:remaining_sample])
  }
  # Pop chosen indices out
  remaining_indices <- all_indices[!(all_indices %in% labeled_indices)]
  
  #### Do the same for unlabeled
  ## Pick a random starting index for the labeled set
  start_index_unlabeled <- sample(1:length(remaining_indices), 1)
  
  ## Calculate labeled_indices
  ## no overflow
  if (start_index_unlabeled + INPUT_unlabeled_sz - 1 <= length(remaining_indices)){
    unlabeled_indices <- remaining_indices[start_index_unlabeled:(start_index_unlabeled + INPUT_unlabeled_sz - 1)]
    
  }else{ #overflow
    ## First part of labeled indices
    unlabeled_indices <- remaining_indices[start_index_unlabeled:length(remaining_indices)]
    ## Calculate remaining needed
    remaining_sample_unlabeled <- INPUT_unlabeled_sz - length(unlabeled_indices)
    ## Add from the beginning
    unlabeled_indices <- c(unlabeled_indices, remaining_indices[1:remaining_sample_unlabeled])
    if(any(is.na(unlabeled_indices))){ print("glitch"); 
      if(sum(!is.na(unlabeled_indices)) > 0){ 
        unlabeled_indices[is.na(unlabeled_indices)] <- sample(remaining_indices, 
                                                    min(length(remaining_indices), sum(is.na(unlabeled_indices))) ) 
      } 
    } 
  }
  
  unlabeled_indices <- na.omit( unlabeled_indices )  
  labeled_indices <- na.omit( labeled_indices )  
  
  ## First labeled_sz docs are the labeled set.
  
  ### Combine unlabeled set and labeled set 
  INPUT_CAT <- as.character( INPUT_CAT  )
  t1 <- table( as.factor(INPUT_CAT)[labeled_indices] )>10
  t2 <- names(  table( as.factor(INPUT_CAT)[unlabeled_indices] ) )  
  good_cats <- names(t1[ t1 == T ])
  good_indices <- (1:length(INPUT_CAT))[INPUT_CAT %in% good_cats]
  
  unlabeled_indices <- unlabeled_indices[ unlabeled_indices %in% good_indices ]
  labeled_indices <- labeled_indices[ labeled_indices %in% good_indices ]
  return(list(labeled_indices = labeled_indices, 
              unlabeled_indices = unlabeled_indices))
} 

sequential_fxn <- function( INPUT_CAT , INPUT_labeled_sz = 100, INPUT_unlabeled_sz = 100){
  ## Get all indices
  all_indices <- 1:length(INPUT_CAT)
  
  ## Pick a random starting index for the labeled set
  start_index <- sample(1:length(all_indices), 1)
  
  ## Calculate joint_indices
  ## no overflow
  if (start_index + INPUT_labeled_sz + INPUT_unlabeled_sz - 1 <= length(all_indices)){
    joint_indices <- all_indices[start_index:(start_index + INPUT_labeled_sz + INPUT_unlabeled_sz - 1)]
  }else{ #overflow
    ## First part of labeled indices
    joint_indices <- all_indices[start_index:length(all_indices)]
    ## Calculate remaining needed
    remaining_sample <- (INPUT_labeled_sz+INPUT_unlabeled_sz) - length(joint_indices)
    ## Add from the beginning
    joint_indices <- c(joint_indices, all_indices[1:remaining_sample])
  }
  
  labeled_indices <- joint_indices[1:floor(length(joint_indices)/2)]
  unlabeled_indices <- joint_indices[-c(1:floor(length(joint_indices)/2))]
  
  labeled_sz  <- table(as.character(   INPUT_CAT[labeled_indices]) )
  unlabeled_indices <- unlabeled_indices[INPUT_CAT[unlabeled_indices] %in% names(labeled_sz) ]
  return(list(labeled_indices = labeled_indices, 
              unlabeled_indices = unlabeled_indices))
}

historical_maxout <- function( INPUT_CAT , INPUT_labeled_sz = 100, max_sz = 1000){
  if(INPUT_labeled_sz > max_sz){INPUT_labeled_sz <- max_sz}
  ## Get all indices
  all_indices <- 1:length(INPUT_CAT)
  
  ## Pick a random starting index for the labeled set
  start_index <- sample(1:length(all_indices), 1)
  
  ## Calculate joint_indices
  ## no overflow
  if (start_index + INPUT_labeled_sz <= length(all_indices)){
    joint_indices <- all_indices[start_index:(start_index + INPUT_labeled_sz )]
  }else{ #overflow
    ## First part of labeled indices
    joint_indices <- all_indices[start_index:length(all_indices)]
    ## Calculate remaining needed
    remaining_sample <- (INPUT_labeled_sz) - length(joint_indices)
    ## Add from the beginning
    joint_indices <- c(joint_indices, all_indices[1:remaining_sample])
  }
  
  labeled_indices <- joint_indices[1:length(joint_indices)]
  select_ = which(!(all_indices %in% labeled_indices))
  unlabeled_indices <- all_indices[sample(select_, min(length(select_), max_sz), replace = F)]
  
  labeled_sz  <- table(as.character(   INPUT_CAT[labeled_indices]) )
  unlabeled_indices <- unlabeled_indices[INPUT_CAT[unlabeled_indices] %in% names(labeled_sz) ]
  return(list(labeled_indices = labeled_indices, 
              unlabeled_indices = unlabeled_indices))
} 

ahistorical_fxn <- function(INPUT_CAT, INPUT_labeled_sz, INPUT_unlabeled_sz){ 
  target_pr_d_divergence <- runif(1, 0, 1)
  n_total_docs <- length(INPUT_CAT)
  category_vec <- as.factor(  INPUT_CAT )  
  category_vec_numeric <- as.numeric(  as.factor(category_vec) )  
  overall_cat_proportions <- prop.table(table( category_vec_numeric ))
  nCat <- length(unique( category_vec_numeric ))
  indices_by_cat_master <- indices_by_cat <- tapply(1:length(INPUT_CAT), category_vec_numeric, function(y) y)
  
  return_trial_pd_div <- c() 
  return_unlabeledsz_indices_list <- return_trainsz_indices_list <- list()  
  minLabeledPerCat = 20
  for(outer_i in 1:10){ 
    candidate_draws <- rdirichlet(n = 500, alpha = rep(1, times = nCat)) 
    colnames(candidate_draws) <- 1:nCat
    tempa <- candidate_draws*INPUT_labeled_sz
    tempa[tempa<minLabeledPerCat] <- 0
    labeled_pd <- candidate_draws[which(rowSums(tempa!=0)>=(max(2,nCat-2)))[1],] #take first as train pd 
    train_target_numb <- sapply(ceiling(labeled_pd * INPUT_labeled_sz), function(x) x)
    train_target_numb[train_target_numb < minLabeledPerCat] <- 0 
    train_target_numb <- round(INPUT_labeled_sz * (train_target_numb/ (sum(train_target_numb))))
    labeled_pd <- prop.table(train_target_numb)
    labeled_pd = labeled_pd[which(labeled_pd > 0)]
    train_target_numb <- train_target_numb[train_target_numb> 0]
    candidate_draws <- candidate_draws[-1,names(labeled_pd)]

    pr_div_vec <- apply(candidate_draws, 1, function(ax){
        unlabeled_pd_cand <- prop.table(sapply(ceiling(ax * INPUT_unlabeled_sz), function(x) x))
      
        unlabeled_target_numb <- unlabeled_pd_cand * INPUT_unlabeled_sz
        
        #get possible indices 
        unlabeled_indices_list <- labeled_indices_list <- list() 
        indices_by_cat <- indices_by_cat_master[names(train_target_numb)]
        for(cati in names(train_target_numb)){
          labeled_indices_list[[cati]] <- unlist(sample(indices_by_cat[[cati]], size = min(c(train_target_numb[cati], 
                                                                                             length(indices_by_cat[[cati]]))), replace = F))
          remaining_cands <- unlist( indices_by_cat[[cati]][!indices_by_cat[[cati]] %in% labeled_indices_list[[cati]]])
          try_t = try(sample(remaining_cands, size = min(c(unlabeled_target_numb[cati], length(remaining_cands))), replace = F), T)
          if(class(try_t) == "try-error"){try_t <- c()}
          unlabeled_indices_list[[cati]] <- try_t
        } 
        labeled_indices <- unlist(labeled_indices_list)
        unlabeled_indices <- unlist(unlabeled_indices_list)
        
        labeled_pd <- prop.table(table(INPUT_CAT[labeled_indices] ) )
        unlabeled_pd <- prop.table(table( INPUT_CAT[unlabeled_indices] ) )
        sum(abs(labeled_pd-unlabeled_pd))
    } ) 
    
    div_from_target <- abs(pr_div_vec - target_pr_d_divergence)
    unlabeled_pd <- candidate_draws[which.min(div_from_target)[1],]
    unlabeled_target_numb <- unlabeled_pd * INPUT_unlabeled_sz

    #get indices 
    unlabeled_indices_list <- labeled_indices_list <- list() 
    indices_by_cat <- indices_by_cat_master[names(train_target_numb)]
    for(cati in names(train_target_numb)){
      labeled_indices_list[[cati]] <- unlist(sample(indices_by_cat[[cati]], size = min(c(train_target_numb[cati], 
                                                                               length(indices_by_cat[[cati]]))), replace = F))
      remaining_cands <- unlist( indices_by_cat[[cati]][!indices_by_cat[[cati]] %in% labeled_indices_list[[cati]]])
      try_t = try(sample(remaining_cands, size = min(c(unlabeled_target_numb[cati], length(remaining_cands))), replace = F), T)
      if(class(try_t) == "try-error"){try_t <- c()}
      unlabeled_indices_list[[cati]] <- try_t
    } 
    labeled_indices <- unlist(labeled_indices_list)
    unlabeled_indices <- unlist(unlabeled_indices_list)
  
    labeled_pd <- prop.table(table(INPUT_CAT[labeled_indices] ) )
    unlabeled_pd <- prop.table(table( INPUT_CAT[unlabeled_indices] ) )
    
    myDiv <- sum(abs(unlabeled_pd - labeled_pd )  )
    return_trainsz_indices_list[[outer_i]] <- labeled_indices
    return_unlabeledsz_indices_list[[outer_i]] <- unlabeled_indices
    return_trial_pd_div[outer_i] <- myDiv ;
  } 
  
  #get final labeled + unlabeled indices 
  nu_size = lapply(return_unlabeledsz_indices_list, function(x){length(x)})
  diff_v <-abs(return_trial_pd_div - target_pr_d_divergence) + 20*(nu_size<25)
  select_index <- which.min(diff_v)[1]
  labeled_indices <- na.omit( return_trainsz_indices_list[[select_index]] )
  unlabeled_indices <- na.omit(  return_unlabeledsz_indices_list[[select_index]] ) 
  
  list(labeled_indices = labeled_indices, 
       unlabeled_indices = unlabeled_indices)
} 

ahistorical_fxn2 <- function(INPUT_CAT, INPUT_labeled_sz, INPUT_unlabeled_sz){
  n_total_docs <- length(INPUT_CAT)
  category_vec <- as.factor(  INPUT_CAT )  
  category_vec_numeric <- as.numeric(  as.factor(category_vec) )  
  overall_cat_proportions <- prop.table(table( category_vec_numeric ))
  nCat <- length(unique( category_vec_numeric ))
  indices_by_cat_master <- tapply(1:length(INPUT_CAT), category_vec_numeric, function(y) y)
  
  outer_ok <- F; outer_counter <- 0; outer_metric_best <- -Inf
  while(outer_ok == F){ 
  counted_ <- 0 ; best_v <- Inf
  while_ok <- F 
  while(while_ok == F){ 
    return_trial_pd_div <- c() 
    return_unlabeledsz_indices_list <- return_trainsz_indices_list <- list()  

    candidate_draws <- rdirichlet(n = 2, alpha = rep(1, times = nCat))
    labeled_pd_target <- candidate_draws[1,]
    unlabeled_pd_target <- candidate_draws[2,]
    names(labeled_pd_target) <- names(unlabeled_pd_target) <- 1:length(unlabeled_pd_target)
    
    #get train indices 
    thres_train <- 30
    train_target_numb <- ceiling(labeled_pd_target * INPUT_labeled_sz)
    unlabeled_target_numb <- ceiling(unlabeled_pd_target * INPUT_unlabeled_sz)
    unlabeled_target_numb[train_target_numb<thres_train] <- 0 
    train_target_numb[train_target_numb<thres_train] <- 0

    IsZeroTrain <- (train_target_numb==0)
    if(mean(IsZeroTrain) <= 0.5 ){
      unlabeled_target_numb <- unlabeled_target_numb[train_target_numb!=0]
      train_target_numb <- train_target_numb[train_target_numb!=0]
      train_target_numb <- ceiling(INPUT_labeled_sz *  prop.table(train_target_numb))
      unlabeled_target_numb <- ceiling(INPUT_unlabeled_sz *  prop.table(unlabeled_target_numb))
      unlabeled_indices_list <- labeled_indices_list <- list() 
      indices_by_cat <- indices_by_cat_master[names(train_target_numb)]
      for(ij in 1:length(train_target_numb)){
        #sort the indices 
        labeled_indices_list[[ij]] <- sample(indices_by_cat[[ij]], size = min(c(train_target_numb[ij], 
                                                                                length(indices_by_cat[[ij]]))), replace = F)
        remaining_cands <- indices_by_cat[[ij]][!indices_by_cat[[ij]] %in% labeled_indices_list[[ij]]]
        unlabeled_indices_list[[ij]] <- sample(remaining_cands, size = min(c(unlabeled_target_numb[ij], 
                                                                             length(remaining_cands))), replace = F)
      } 
      if(length(unlist(unlabeled_indices_list)) > 30){ 
        while_ok <- T
      }
    } 
    
    if(mean(IsZeroTrain) > 0.5){
      while_ok <- F
      if( mean(IsZeroTrain==0) <= best_v) { 
        train_target_numb_best <- train_target_numb
        unlabeled_target_numb_best <- unlabeled_target_numb
        best_v <- mean(IsZeroTrain)
      }
    } 
      
    counted_ <- counted_ + 1 
    if(counted_  > 100000){
      while_ok <- T
      train_target_numb <- train_target_numb_best
      unlabeled_target_numb <- unlabeled_target_numb_best
    }
  }
  
    unlabeled_target_numb <- unlabeled_target_numb[train_target_numb!=0]
    train_target_numb <- train_target_numb[train_target_numb!=0]
    train_target_numb <- ceiling(INPUT_labeled_sz *  prop.table(train_target_numb))
    unlabeled_target_numb <- ceiling(INPUT_unlabeled_sz *  prop.table(unlabeled_target_numb))
    unlabeled_indices_list <- labeled_indices_list <- list() 
    indices_by_cat <- indices_by_cat_master[names(train_target_numb)]
    for(ij in 1:length(train_target_numb)){
      #sort the indices 
      labeled_indices_list[[ij]] <- sample(indices_by_cat[[ij]], size = min(c(train_target_numb[ij], 
                                                       length(indices_by_cat[[ij]]))), replace = F)
      remaining_cands <- indices_by_cat[[ij]][!indices_by_cat[[ij]] %in% labeled_indices_list[[ij]]]
      unlabeled_indices_list[[ij]] <- sample(remaining_cands, size = min(c(unlabeled_target_numb[ij], 
                                                                           length(remaining_cands))), replace = F)
    } 
    
    labeled_indices <- unlist(labeled_indices_list)
    unlabeled_indices <- unlist(unlabeled_indices_list)
  
    A1 <- table(as.character(INPUT_CAT[labeled_indices]))
    A2 <- table(as.character(INPUT_CAT[unlabeled_indices]))
    if( length(unlabeled_indices) < INPUT_unlabeled_sz-10 | length(A1) != length(A2)  ){
      outer_metric <- length( unlabeled_indices )
      if(outer_metric >= outer_metric_best){ 
        labeled_indices_best <- labeled_indices_list; 
        unlabeled_indices_best <- unlabeled_indices_list; 
      }
      outer_ok <- F 
    }

    if( outer_counter > 100  ){ 
        outer_ok <- T;
        labeled_indices_best <- labeled_indices_best[lapply(unlabeled_indices_best, length)>0]
        unlabeled_indices_best <- unlabeled_indices_best[lapply(unlabeled_indices_best, length)>0]
        labeled_indices <- unlist(labeled_indices_best)
        unlabeled_indices <- unlist(unlabeled_indices_best)
    }
    if(  (length(unlabeled_indices) >= INPUT_unlabeled_sz-10) & (length(A1) == length(A2)) ){outer_ok <- T  }
    outer_counter <- outer_counter + 1 
  }
    
    labeled_pd <- table( INPUT_CAT[labeled_indices] ) / sum(table( INPUT_CAT[labeled_indices] ) ) 
    unlabeled_pd <- table( INPUT_CAT[unlabeled_indices] ) / sum(table( INPUT_CAT[unlabeled_indices] ) ) 
      
  list(labeled_indices = labeled_indices, 
       unlabeled_indices = unlabeled_indices)
} 

aykut_fxn <- function(INPUT_CAT , INPUT_labeled_sz = 100, INPUT_unlabeled_sz = 100, 
                      previousTestSize=NULL){ 
  #function (INPUT_CAT, labeledCategorySizes, , previousTestSize=NULL) 
    minTestSize = 10 
    fixedTrainingSizeGenerator <- function(categoryLabels, N=30, previousTrainingSize=NULL){
        categoryLabels<-sort(unique(INPUT_CAT))
        labeledCategorySizes<-rep(N,length(categoryLabels))
        names(labeledCategorySizes)<-categoryLabels
        labeledCategorySizes
    }
  
    getPrunedSize <-  function(coef,size, minN=1){
        max.index<-which.max(coef)
        max.value<-max(coef)
        prunedSize<-round(coef*(size[max.index]/max.value)) 
        removalCounter<-1
        while (any(((size-prunedSize)/max.value) < -0.01) & removalCounter < 1000) {
          prunedSize <- round(coef*((size[max.index]-removalCounter)/max.value));
          removalCounter<-removalCounter+1;
        }	
        if(any(prunedSize < 0)){ 
          print("PRUNE ERROR")
          prunedSize<-round(coef(size[max.index]/max.value)) 
        }
        prunedSize[prunedSize<min(size,minN)]<-min(size,minN)
        prunedSize
      }
    
    labeledCategorySizes <- fixedTrainingSizeGenerator(categoryLabels= INPUT_CAT, N = INPUT_labeled_sz / length(unique(INPUT_CAT)) )
    
    #if (any((table(INPUT_CAT) - labeledCategorySizes) < minTestSize)) 
      #stop("Test size satisfying the minimum unlabeled size requirement cannot be generated")
    my_tab <- table(INPUT_CAT)
    my_tab[my_tab-labeledCategorySizes < minTestSize] <- 0 
    if(is.null(previousTestSize)) startingProps <- prop.table(my_tab)
    else startingProps <- prop.table(previousTestSize)
  
    counter_ <- 0 
    repeat {  
      unif_samp <- runif(1)
      if(unif_samp < .2) { props<- c(rdirichlet(n=1, alpha = startingProps * 5))  } 
      counter_ <- counter_ + 1 
      if(unif_samp >= 0.2){props<- c(rdirichlet(n=1, alpha = startingProps * 100)) }
      temp_ <- table(INPUT_CAT) - labeledCategorySizes
      temp_[temp_<0] <- 3
      sizes <- getPrunedSize(props, temp_)
    if(all(sizes >= minTestSize)){  break } 
    if(counter_ > 300){ break } 
    }
  
    names(sizes) <- names(labeledCategorySizes)
    unlabeledCategorySizes <- sizes
    unlabeledCategorySizes[sizes==0 | labeledCategorySizes < 10] <- 0 
    labeledCategorySizes[sizes==0 | labeledCategorySizes < 10] <- 0 
    labeledCategorySizes <- round(labeledCategorySizes/sum(labeledCategorySizes) * INPUT_labeled_sz)
    unlabeledCategorySizes <- round(unlabeledCategorySizes/sum(unlabeledCategorySizes) * min(sum(unlabeledCategorySizes), 
                                                                        750))
    
    INPUT_CAT_which <- tapply(1:length(INPUT_CAT), INPUT_CAT, c)
    Indices_list <- sapply(1:length(labeledCategorySizes ), 
           function(x){ 
             CandidateCat_X <- unlist(  INPUT_CAT_which[names(labeledCategorySizes)[x]] )
             TrainCat_x <- sample(CandidateCat_X , 
                     min(length(CandidateCat_X), labeledCategorySizes[x]), replace = F)
             RemainingCat_X <-  CandidateCat_X[!CandidateCat_X %in% TrainCat_x]
             TestCat_x <- sample( RemainingCat_X,
                                   min(unlabeledCategorySizes[x],length(RemainingCat_X)), replace = F)
             list(TrainCat_x=TrainCat_x, 
                  TestCat_x=TestCat_x)
             })

    list(labeled_indices = unlist( Indices_list[1,]), 
         unlabeled_indices = unlist( Indices_list[2,]))
}

aykut_fxn_quantification <- function(INPUT_CAT , INPUT_labeled_sz = 100, INPUT_unlabeled_sz = 100){ 
  starting_v <- sample(1:length(INPUT_CAT), 1)
  labeled_indices <- c(starting_v:min(c(starting_v+INPUT_labeled_sz, length(INPUT_CAT))))
  if(length(labeled_indices)<INPUT_labeled_sz){labeled_indices <- c(labeled_indices, 1:(INPUT_labeled_sz-length(labeled_indices)))}
  labeledCategorySizes <- table(INPUT_CAT [ labeled_indices])
  labeledCategorySizes[labeledCategorySizes<10] <- 0 
  labeledCategorySizes <- labeledCategorySizes[labeledCategorySizes>0]
  labeled_pd <- labeledCategorySizes/sum(labeledCategorySizes)
  unlabeled_pd <- c(rdirichlet(n = 1, alpha = rep(1, length(labeled_pd))))
  unlabeled_pd <- unlabeled_pd/sum(unlabeled_pd)
  
  unlabeledCategorySizes <- ceiling( INPUT_unlabeled_sz * unlabeled_pd ) 
  unlabeledCategorySizes <- round(INPUT_unlabeled_sz * unlabeledCategorySizes /sum(unlabeledCategorySizes))
  labeledCategorySizes <- round(INPUT_unlabeled_sz * labeledCategorySizes /sum(labeledCategorySizes))

  #unlabeledCategorySizes/labeledCategorySizes / sum(   unlabeledCategorySizes/labeledCategorySizes )

  INPUT_CAT_which <- tapply(1:length(INPUT_CAT), INPUT_CAT, c)
  Indices_list <- sapply(1:length(labeledCategorySizes ), 
                         function(x){ 
                           CandidateCat_X <- which(INPUT_CAT == names(labeledCategorySizes)[x])
                           candi_  <- CandidateCat_X[!CandidateCat_X %in% labeled_indices]
                           TestCat_x <- sample( candi_, 
                                                min(length(candi_), 
                                                    unlist(unlabeledCategorySizes[x])), replace = F)
                           if(length(TestCat_x) < 5){TestCat_x <- c()}
                           list(labeled_indices=labeled_indices, 
                                TestCat_x=TestCat_x)
                         })
  unlabeled_indices <- unlist( Indices_list[2,] )

  candi__ <- (1:length(INPUT_CAT))[! (1:length(INPUT_CAT) %in% c( unlabeled_indices,labeled_indices))]
  unlabeled_indices <- c(unlabeled_indices, 
                    sample( candi__ , min(length(candi__), abs(INPUT_unlabeled_sz - length(unlabeled_indices))), 
                            replace = F))
  
  list(labeled_indices = labeled_indices, 
       unlabeled_indices = unlabeled_indices )
} 

breakdown_sample <- function(INPUT_CAT , INPUT_labeled_sz = 100, INPUT_unlabeled_sz = 100){ 
  DELE_OK <- F
  DELE_COUNT <- 0 
  previousBest <- Inf
  train_val <- runif(1,0, 0.1)
  unlabeled_val <- runif(1,0.25, 0.5)
  while(DELE_OK == F){ 
    DELE_COUNT <- DELE_COUNT + 1 
    all_indices <- 1:length(INPUT_CAT)
    starting_v <- sample(all_indices, 1)
    labeled_indices <- c(starting_v:min(c(starting_v+INPUT_labeled_sz, length(INPUT_CAT))))
    if(length(labeled_indices)<INPUT_labeled_sz){labeled_indices <- c(labeled_indices, 1:(INPUT_labeled_sz-length(labeled_indices)))}
    
    remaining_indices <- all_indices[!all_indices %in% labeled_indices]
    starting_v <- sample(1:length(remaining_indices), 1)
    unlabeled_indices <- remaining_indices[ c(starting_v:min(c(starting_v+INPUT_unlabeled_sz, length(remaining_indices)))) ] 
    unlabeled_indices_orig <- unlabeled_indices
    if(length(unlabeled_indices)<INPUT_unlabeled_sz){
      mainder <- remaining_indices[!remaining_indices %in% unlabeled_indices]
      unlabeled_indices <- c(unlabeled_indices, 
                  sample(mainder, max(0,min(length(mainder), INPUT_unlabeled_sz-length(unlabeled_indices)))))
    } 
    labeledCategoryProp <- table(INPUT_CAT [ labeled_indices])
    labeledCategoryProp[labeledCategoryProp < 10] <- 0 
    labeledCategoryProp <- labeledCategoryProp[labeledCategoryProp>0]
    labeledCategoryProp <- labeledCategoryProp /sum(labeledCategoryProp)
    unlabeledCategoryProp <- try(table(INPUT_CAT [ unlabeled_indices])[names(labeledCategoryProp )], T)  
    unlabeledCategoryProp <- unlabeledCategoryProp/sum(unlabeledCategoryProp)
  
    value_proposition <- try(min( sqrt( abs(labeledCategoryProp - train_val)^2 + abs(unlabeledCategoryProp - unlabeled_val)^2  ) ) , T)  
    if(class(value_proposition) == "try-error"){ value_proposition <- Inf }
    if( length(labeledCategoryProp) != length(unlabeledCategoryProp) ){
      value_proposition <- Inf
    }
    
    if(value_proposition < previousBest){
      labeled_indices_keep <- labeled_indices; 
      unlabeled_indices_keep <- unlabeled_indices
      previousBest <- value_proposition
    }
    if( DELE_COUNT > 10000 ){ DELE_OK <- T}
  }
  
  return(  list(labeled_indices = labeled_indices_keep, 
       unlabeled_indices = na.omit(unlabeled_indices_keep) ) )  
} 

breakdown_sample2 <- function(INPUT_CAT , INPUT_labeled_sz = 100, INPUT_unlabeled_sz = 100, PROJECTIONS_INPUT=NULL){ 
  mySharpy <- colSums( ( t(PROJECTIONS_INPUT) - colMeans(PROJECTIONS_INPUT) )^2 / apply(PROJECTIONS_INPUT, 2, var) )
  mySharpy <- mySharpy + rnorm(length(mySharpy), mean = 0, sd = 0.0001 * sd(mySharpy))
  mySharpy_sorted <- sort(mySharpy, decreasing = T)
  labeled_indices_keep <- which(mySharpy >= mySharpy_sorted[INPUT_labeled_sz ])
  remaining_indices <- (1:length(mySharpy))[!(1:length(mySharpy) %in% labeled_indices_keep)]
  unlabeled_indices_keep <- sample(remaining_indices , 
                               min(length(remaining_indices), INPUT_unlabeled_sz), replace =F ) 
  
  return(  list(labeled_indices = labeled_indices_keep, 
                unlabeled_indices = na.omit(unlabeled_indices_keep) ) )
} 

XDiv_helper_fxn <- function(INPUT_CAT , INPUT_labeled_sz_ = 100, INPUT_unlabeled_sz_ = 100, PROJECTIONS_INPUT2 =NULL){ 
  n_cand <- 1000
  myDiv_vec <- rep(NA, times = n_cand)
  labeled_mat <- matrix(logical(), nrow = n_cand, ncol = INPUT_labeled_sz_)
  unlabeled_mat <- matrix(logical(), nrow = n_cand, ncol = INPUT_unlabeled_sz_)
  for(xcv in 1:n_cand){
    labeled_indices <- sample(1:nrow(PROJECTIONS_INPUT2), size = INPUT_labeled_sz_, replace = F)
    remaining_indices <- (1:nrow(PROJECTIONS_INPUT2))[!(1:nrow(PROJECTIONS_INPUT2) %in% labeled_indices)]
    unlabeled_indices <- sample(remaining_indices, size = INPUT_unlabeled_sz_, replace = F)
    
    DOCS_TRAIN <- PROJECTIONS_INPUT2[labeled_indices,]
    DOCS_TEST <- PROJECTIONS_INPUT2[unlabeled_indices,]
    X_L <- try(tapply(1:nrow(DOCS_TRAIN), as.character(INPUT_CAT[labeled_indices]), 
                      function(as){colMeans(DOCS_TRAIN[as,])}), T)
    X_L <- try(do.call(rbind, X_L), T) 
    
    X_U <- try(tapply(1:nrow(DOCS_TEST), as.character(INPUT_CAT[unlabeled_indices]), 
                      function(as){colMeans(DOCS_TEST[as,])}), T)
    X_U <- try(do.call(rbind, X_U), T) 
    my_div <- try(mean(abs(X_L - X_U)), T)
    if(class(my_div) == "try-error" | (length(X_L) != length(X_U))){my_div <- Inf}
    myDiv_vec[xcv] <- my_div
    labeled_mat[xcv,] <- labeled_indices
    unlabeled_mat[xcv,] <- unlabeled_indices
  }  
  
  return(list(myDiv_vec = myDiv_vec, 
              labeled_mat = labeled_mat, 
              unlabeled_mat = unlabeled_mat))
}

Uniform_XDiv <- function(INPUT_DATA, INPUT_CAT , INPUT_labeled_sz = 100, INPUT_unlabeled_sz = 100, PROJECTIONS_INPUT=NULL){ 
  XDiv_helper_results <- XDiv_helper_fxn(INPUT_CAT = INPUT_CAT , INPUT_labeled_sz_ = INPUT_labeled_sz, 
                                         INPUT_unlabeled_sz_ = INPUT_unlabeled_sz, PROJECTIONS_INPUT2=PROJECTIONS_INPUT)
  myDiv_vec <- XDiv_helper_results$myDiv_vec
  labeled_mat <- XDiv_helper_results$labeled_mat
  unlabeled_mat <- XDiv_helper_results$unlabeled_mat
  
  myDiv_vec[abs(myDiv_vec) == Inf] <- NA
  target_div <- runif(1, min(myDiv_vec, na.rm = T), max(myDiv_vec, na.rm = T))
  dist_value <- abs(myDiv_vec - target_div)
  best_index <- which(dist_value == min(dist_value, na.rm = T) )[1]
  labeled_indices <- labeled_mat[best_index,]
  unlabeled_indices <- unlabeled_mat[best_index,]

  return(  list(labeled_indices = labeled_indices, 
                unlabeled_indices = unlabeled_indices ) ) 
} 

Max_XDiv <- function(INPUT_CAT , INPUT_labeled_sz = 100, INPUT_unlabeled_sz = 100, PROJECTIONS_INPUT=NULL){ 
  XDiv_helper_results <- XDiv_helper_fxn(INPUT_CAT = INPUT_CAT , INPUT_labeled_sz_ = INPUT_labeled_sz, 
                                         INPUT_unlabeled_sz_ = INPUT_unlabeled_sz, PROJECTIONS_INPUT2=PROJECTIONS_INPUT)
  myDiv_vec <- XDiv_helper_results$myDiv_vec
  labeled_mat <- XDiv_helper_results$labeled_mat
  unlabeled_mat <- XDiv_helper_results$unlabeled_mat
  
  myDiv_vec[abs(myDiv_vec) == Inf] <- NA
  best_index <- which(myDiv_vec == max(myDiv_vec, na.rm = T) )[1]
  labeled_indices <- labeled_mat[best_index,]
  unlabeled_indices <- unlabeled_mat[best_index,]

  return(  list(labeled_indices = labeled_indices, 
                unlabeled_indices = unlabeled_indices ) ) 
} 

Min_XDiv <- function(INPUT_DATA, INPUT_CAT , INPUT_labeled_sz = 100, INPUT_unlabeled_sz = 100, PROJECTIONS_INPUT=NULL){ 
  XDiv_helper_results <- XDiv_helper_fxn(INPUT_CAT = INPUT_CAT , INPUT_labeled_sz_ = INPUT_labeled_sz, 
                                         INPUT_unlabeled_sz_ = INPUT_unlabeled_sz, PROJECTIONS_INPUT2=PROJECTIONS_INPUT)
  myDiv_vec <- XDiv_helper_results$myDiv_vec
  labeled_mat <- XDiv_helper_results$labeled_mat
  unlabeled_mat <- XDiv_helper_results$unlabeled_mat
  
  myDiv_vec[abs(myDiv_vec) == Inf] <- NA
  best_index <- which(myDiv_vec == min(myDiv_vec, na.rm = T) )[1]
  labeled_indices <- labeled_mat[best_index,]
  unlabeled_indices <- unlabeled_mat[best_index,]
  
  return(  list(labeled_indices = labeled_indices, 
                unlabeled_indices = unlabeled_indices ) ) 
} 


