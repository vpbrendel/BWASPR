#' annotate_methylome()
#' This function annotates the methylome with different genomic features (e.g. genes, exon, promoter, etc.)
#'
#' @param mrobj A methylRawList object that is generated by mcalls2mkobj()
#' @param genome_ann A list of GRanges objects that contain genome annotation. 
#' @param destrand methylKit::unite() parameter; default: FALSE.
#'   destrand=TRUE combines CpG methylation calls from both strands
#' @param mc.cores Integer denoting how many cores should be used for parallel
#'   diffential methylation calculations
#' @param outfile If specified as other than "", the result is saved in the
#'   specified file. 
#'
#' @return A table that displays site methylation percentages and annotation
#'
#' @importFrom methylKit percMethylation unite
#' @importFrom genomation annotateWithFeature
#'
#' @examples
#'   mydatf <- system.file("extdata","Am.dat",package="BWASPR")
#'   myparf <- system.file("extdata","Am.par",package="BWASPR")
#'   myfiles <- setup_BWASPR(datafile=mydatf,parfile=myparf)
#'   AmHE <- mcalls2mkobj(myfiles$datafiles)
#'   genome_ann <- get_genome_annotation(myfiles$parameters)
#'   annotate_methylome(AmHE,genome_ann,mc.cores=4,
#'                      outfile="AmHE_methylome_ann.txt")
#'
#' @export


annotate_methylome <- function(mrobj,
                               genome_ann,destrand=FALSE,mc.cores=mc.cores,
                               outfile="methylome_ann.txt"
                              ) {
    message("... annotating the methylome ...")
    # ... unite all the methylRawList elements into a methylBase object and calculate
    #   the percentage methylation scores:
    #
    meth      <- unite(mrobj,destrand=destrand,mc.cores=mc.cores)
    perc_meth <- round(percMethylation(meth,rowids=FALSE,save.txt=FALSE),2)

    # ... annotate the methylome with generic genome features as provided by
    #   genome_ann and add respective columns to meth@.Data:
    #
    for (feature in names(genome_ann)) {
        vname <- paste(feature,"ann",sep="_")
        assign(vname,
               annotateWithFeature(as(meth,'GRanges'),
                                   genome_ann[[feature]],
                                   strand=FALSE)
              )
        meth[feature] <- get(vname)@members
    }

    # ... pull out select columns from the meth object and return an expanded
    #   data frame with methylome annotation:
    #
    meth_data  <- getData(meth)
    slctddata  <- subset(meth_data,
                         select=c('chr','start','end','strand',names(genome_ann))
                        )
    methylome_ann <- cbind(perc_meth,slctddata)
    # ... remove duplicated columns in case experiments are duplicated in the input,
    #   for example, to get statistics on a single experiment using this function
    #   that requires a list as input
    methylome_ann <- methylome_ann[, !duplicated(colnames(methylome_ann))]
    if (outfile != "") {
        write.table(methylome_ann,file=outfile,sep='\t',row.names=FALSE,
                    quote=FALSE)
    }
    message("... done ...")
    return(methylome_ann)
}
