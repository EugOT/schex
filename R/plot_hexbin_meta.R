#' Plot of meta data of single cell data in bivariate hexagon cells.
#'
#' @param sce A \code{\link[SingleCellExperiment]{SingleCellExperiment}}
#'   or \code{\link[Seurat]{Seurat}} object.
#' @param col A string referring to the name of one column in the meta data of
#'   sce by which to colour the hexagons.
#' @param action A string specifying how meta data of observations in
#'   binned  hexagon cells are to be summarized. Possible actions are
#'   \code{majority}, \code{prop}, \code{prop_0}, \code{mode}, \code{mean} and
#'   \code{median} (see details).
#' @param no An integer specifying which level to plot of the column. Only in
#'   effect when \code{action=prop}.
#' @param colors A vector of strings specifying which colors to use for plotting
#'    the different levels in the selected column of the meta data. Only in
#'    effect when the selected \code{action="majority"}.
#' @param title A string containing the title of the plot.
#' @param xlab A string containing the title of the x axis.
#' @param ylab A string containing the title of the y axis.
#'
#' @details This function plots any column of the meta data in the hexagon cell
#'   representation calculated with \code{\link{make_hexbin}}. The chosen meta
#'   data column is summarized by one of six actions \code{majority},
#'   \code{prop}, \code{prop_0}, \code{mode}, \code{mean} and \code{median}:
#'
#'   \describe{
#'     \item{\code{majority}}{Returns the value of the majority of observations
#'      in the bin. The associated meta data column needs to be a factor
#'      or character.}
#'     \item{\code{prop}}{Returns the proportion of each level or unique
#'      character in the bin. The associated meta data column needs to be a
#'      factor or character.}
#'     \item{\code{prop_0}}{Returns the proportion of observations in the bin
#'      greater than 0. The associated meta data column needs to be numeric.}
#'     \item{\code{mode}}{Returns the mode of the observations in the bin. The
#'      associated meta data column needs to be numeric.}
#'     \item{\code{mean}}{Returns the mean of the observations in the bin. The
#'      associated meta data column needs to be numeric.}
#'      \item{\code{median}}{Returns the median of the observations in the bin.
#'      The associated meta data column needs to be numeric.}
#'   }
#'
#' @return A \code{\link{ggplot2}{ggplot}} object.
#' @import Seurat
#' @import SingleCellExperiment
#' @import ggplot2
#' @importFrom dplyr as_tibble
#' @export
#'
#' @examples
#' #' # For Seurat object
#' library(Seurat)
#' data("pbmc_small")
#' pbmc_small <- make_hexbin(pbmc_small, 10, dimension_reduction = "PCA")
#' plot_hexbin_meta(pbmc_small, col="RNA_snn_res.1", action="prop", no=1)
#' plot_hexbin_meta(pbmc_small, col="RNA_snn_res.1", action="prop", no=2)
#' # For SingleCellExperiment object
#' \dontrun{
#' library(TENxPBMCData)
#' library(scater)
#' tenx_pbmc3k <- TENxPBMCData(dataset = "pbmc3k")
#' rm_ind <- calculateAverage(tenx_pbmc3k)<0.1
#' tenx_pbmc3k <- tenx_pbmc3k[-rm_ind,]
#' colData(tenx_pbmc3k) <- cbind(colData(tenx_pbmc3k),
#'      perCellQCMetrics(tenx_pbmc3k))
#' tenx_pbmc3k <- normalize(tenx_pbmc3k)
#' tenx_pbmc3k <- runPCA(tenx_pbmc3k)
#' tenx_pbmc3k <- make_hexbin( tenx_pbmc3k, 20, dimension_reduction = "PCA")
#' plot_hexbin_meta(tenx_pbmc3k, col="total_counts", action="median")
#' }
setGeneric("plot_hexbin_meta", function(sce,
      col,
      action,
      no = 1,
      colors=NULL,
      title=NULL,
      xlab=NULL,
      ylab=NULL) standardGeneric("plot_hexbin_meta"))

#' @export
#' @describeIn plot_hexbin_meta  Plot of meta data into hexagon cell for
#'   SingleCellExperiment object.
setMethod("plot_hexbin_meta", "SingleCellExperiment", function(sce,
                                                               col,
                                                               action,
                                                               no = 1,
                                                               colors=NULL,
                                                               title=NULL,
                                                               xlab=NULL,
                                                               ylab=NULL) {

  out <- sce@metadata$hexbin[[2]]
  cID <- sce@metadata$hexbin[[1]]

  if(is.null(out)){
    stop("Compute hexbin representation before plotting.")
  }

  if (any(!col %in% colnames(colData(sce)))) {
    stop("Column cannot be found in colData(sce).")
  }

  name_s <- paste0("sce$", col)
  func <- paste0("x <- ", name_s)

  eval(parse(text = func))

  hh <- .make_hexbin_function(x, action, cID)
  out <- as_tibble(out)

  if (action == "prop"|action=="majority") {
    if(action == "prop"){
      col_hh <- .make_hexbin_colnames(x,col)
      func1 <- paste0("out$", col_hh, " <- hh[,", seq(1,length(col_hh),1),"]")
      for(i in seq_len(length(func1))){
        eval(parse(text=func1[i]))
      }
    }
    if(action == "majority"){
      col_hh <-paste0(col, "_", action)
      if(is.factor(x)){
        func1 <- paste0("out$", col_hh, " <- factor(hh, levels=",
              "levels(x))")
      } else {
        func1 <- paste0("out$", col_hh, " <- hh")
      }
      eval(parse(text=func1))
    }
  } else {
    col_hh <-paste0(col, "_", action)
    func1 <- paste0("out$", col_hh, " <- hh")
    eval(parse(text=func1))
  }


  if(action!="prop"){

    if(action=="majority"){

      .plot_hexbin(out, colour_by=col_hh, colors=colors,
                   title=title, xlab=xlab, ylab=ylab)

    } else {

      .plot_hexbin(out, colour_by=col_hh, colors=NULL,
          title=title, xlab=xlab, ylab=ylab)
    }

  } else {

   .plot_hexbin(out, colour_by=col_hh[no], colors=NULL,
                title=title, xlab=xlab, ylab=ylab)

  }

})

#' @export
#' @describeIn plot_hexbin_meta  Plot of meta data into hexagon cell for
#'   Seurat object.
setMethod("plot_hexbin_meta", "Seurat", function(sce,
                                                               col,
                                                               action,
                                                               no = 1,
                                                               colors=NULL,
                                                               title=NULL,
                                                               xlab=NULL,
                                                               ylab=NULL) {

  out <- sce@misc$hexbin[[2]]
  cID <- sce@misc$hexbin[[1]]

  if(is.null(out)){
    stop("Compute hexbin representation before plotting.")
  }

  if (any(!col %in% colnames(sce@meta.data))) {
    stop("Column cannot be found in slot(sce, 'meta.data').")
  }

  name_s <- paste0("sce$", col)
  func <- paste0("x <- ", name_s)

  eval(parse(text = func))

  hh <- .make_hexbin_function(x, action, cID)
  out <- as_tibble(out)

  if (action == "prop"|action=="majority") {
    if(action == "prop"){
      col_hh <- .make_hexbin_colnames(x,col)
      func1 <- paste0("out$", col_hh, " <- hh[,", seq(1,length(col_hh),1),"]")
      for(i in seq_len(length(func1))){
        eval(parse(text=func1[i]))
      }
    }
    if(action == "majority"){
      col_hh <-paste0(col, "_", action)
      if(is.factor(x)){
        func1 <- paste0("out$", col_hh, " <- factor(hh, levels=",
                        "levels(x))")
      } else {
        func1 <- paste0("out$", col_hh, " <- hh")
      }
      eval(parse(text=func1))
    }
  } else {
    col_hh <-paste0(col, "_", action)
    func1 <- paste0("out$", col_hh, " <- hh")
    eval(parse(text=func1))
  }

  if(action!="prop"){

    if(action=="majority"){

      .plot_hexbin(out, colour_by=col_hh, colors=colors,
                   title=title, xlab=xlab, ylab=ylab)

    } else {

      .plot_hexbin(out, colour_by=col_hh, colors=NULL,
                   title=title, xlab=xlab, ylab=ylab)
    }

  } else {

    .plot_hexbin(out, colour_by=col_hh[no], colors=NULL,
                 title=title, xlab=xlab, ylab=ylab)

  }

})

.plot_hexbin <- function(drhex, colour_by="Cluster_majority", colors=NULL,
                        title=NULL, xlab=NULL, ylab=NULL) {

  if (any(!c("x", "y", colour_by) %in% colnames(drhex))) {
    stop("The dataframe must contain columns named 'x', 'y' and label.")
  }

  if(is.null(title)) {
    title <- colour_by
  }

  if(is.null(xlab)) {
    xlab <- "x"
  }

  if(is.null(ylab)) {
    ylab <- "y"
  }

  if(grepl("majority", colour_by)){

    if(is.null(colors)){

      ggplot(drhex, aes_string("x", "y", fill=colour_by)) +
       geom_hex(stat = "identity") +
        theme_classic() + theme(legend.position="bottom") + ggtitle(title) +
        labs(x=xlab, y=ylab) + theme(legend.title=element_blank())

    } else {

      ggplot(drhex, aes_string("x", "y", fill=colour_by)) +
        geom_hex(stat = "identity") + scale_fill_manual(values=colors) +
        theme_classic() + theme(legend.position="bottom") + ggtitle(title) +
        labs(x=xlab, y=ylab) + theme(legend.title=element_blank())

    }

  } else {

    ggplot(drhex, aes_string("x","y", fill=colour_by)) +
      geom_hex(stat = "identity") +
      theme_classic() + scale_fill_viridis_c() + ggtitle(title) +
      labs(x=xlab, y=ylab) + theme(legend.title=element_blank())

  }

}

