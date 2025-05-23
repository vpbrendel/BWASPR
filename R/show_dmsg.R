#' show_dmsg() 
#'   This function generates will plot heatmaps of methylation level of sites in dmgenes
#'
#' @param mrobj A methylKit methylRaw or methylRawList object
#' @param dmsg A list containing GRanges objects dmsites and dmgenes returned by
#'   det_dmsg()
#' @param min.nsites Required minimal number of msites in a gene for the gene
#'   to be displayed in the heatmap pdf
#' @param max.nsites Required maximal number of msites in a gene for the gene
#'   to be displayed in the heatmap pdf
#' @param min.pdmsites Required minimal percent of dmsites among the msites in
#'   a gene for the gene to be displayed in the heatmap pdf
#' @param destrand methylKit::unite() parameter; default: FALSE.
#'   destrand=TRUE combines CpG methylation calls from both strands
#' @param mc.cores Integer denoting how many cores should be used for parallel
#'   diffential methylation calculations
#' @param outflabel A string to identify the study in the output file
#' 
#' @return A data frame
#' 
#' @importFrom methylKit percMethylation reorganize unite
#' @importFrom GenomicRanges findOverlaps values
#' @importFrom gplots heatmap.2 greenred
#' @importFrom S4Vectors subjectHits queryHits
#' @importFrom dplyr %>% group_by_
#'
#' @examples
#'   mydatf <- system.file("extdata","Am.dat",package="BWASPR")
#'   myparf <- system.file("extdata","Am.par",package="BWASPR")
#'   myfiles <- setup_BWASPR(datafile=mydatf,parfile=myparf)
#'   samplelist <- list("forager","nurse")
#'   AmHE <- mcalls2mkobj(myfiles$datafiles,species="Am",study="HE",
#'                        sample=samplelist,replicate=c(0),
#'                        type="CpGhsm",mincov=1,assembly="Amel-4.5")
#'   genome_ann <- get_genome_annotation(myfiles$parameters)
#'   dmsgList <- det_dmsg(AmHE,genome_ann,
#'                        threshold=25.0,qvalue=0.01,mc.cores=4,destrand=TRUE,
#'                        outfile1="AmHE-dmsites.txt", 
#'                        outfile2="AmHE-dmgenes.txt")
#'   dmgprp <- show_dmsg(AmHE,dmsgList,destrand=TRUE,
#'                       min.nsites=2,max.nsites=60,min.pdmsites=10,
#'                       mc.cores=4,outflabel="Am_HE")
#'
#' @export

show_dmsg <- function(mrobj,dmsg,destrand=FALSE,min.nsites=2,max.nsites=60,
                      min.pdmsites=10,mc.cores=1,outflabel="") {
    message('... show_dmsg() ...')
    # load dmsites and dmgenes and sample_match_list
    dmsites.gr          <- do.call("c", dmsg$dmsites)
    dmgenes.gr          <- do.call("c", dmsg$dmgenes)
    sample_match_list   <- as.list(unique(as.character(dmgenes.gr$comparison)))
    # ... let's see whether there are any cores left for inside the mclapply
    #     loop:
    mc <- max(floor((mc.cores - length(sample_match_list)) /
                    length(sample_match_list)), 1)
    # analyze each sample_match
    dmgprp <- mclapply(sample_match_list, function(sample_match) {
        sample1         <- unlist(strsplit(sample_match,'\\.'))[1]
        sample2         <- unlist(strsplit(sample_match,'\\.'))[3]
        message(paste('... comparing ',sample1,' vs. ',sample2,' ...',sep=''))
        # subset the dmsites.gr & dmgenes.gr with this sample_match
        #
        pair_dmsites.gr <- dmsites.gr[GenomicRanges::values(dmsites.gr)$comparison%in%sample_match]
        pair_dmgenes.gr <- dmgenes.gr[GenomicRanges::values(dmgenes.gr)$comparison%in%sample_match]
        # subset the mrobj with current sample_match
        #
        pair_mrobj      <- reorganize(mrobj,sample.ids=list(sample1,sample2),
                                      treatment=c(0,1))
        pair_meth       <- unite(pair_mrobj,destrand=destrand,mc.cores=mc)
        # calc methylation level
        #
        p_meth          <- round(percMethylation(pair_meth,rowids=FALSE,
                                                 save.txt=FALSE),2)
        pair_p_meth     <- cbind(pair_meth,p_meth)
        pair_p_meth.gr  <- as(pair_p_meth,'GRanges')
        # identify scd sites in each gene
        #
        match                 <- suppressWarnings(findOverlaps(pair_dmgenes.gr,pair_p_meth.gr,ignore.strand=TRUE))
        sub_pair_p_meth.gr    <- pair_p_meth.gr[subjectHits(match)]
        sub_pair_dmgenes.gr   <- pair_dmgenes.gr[queryHits(match)]
        # identify dmsites in scd sites
        #
        match2                <- suppressWarnings(findOverlaps(sub_pair_p_meth.gr,pair_dmsites.gr,ignore.strand=TRUE))
        pair_dmsites_index    <- queryHits(match2)
        # transform GRanges objects to dataframes and combine them
        #
        sub_pair_p_meth            <- as.data.frame(sub_pair_p_meth.gr)
        sub_pair_dmgenes           <- as.data.frame(sub_pair_dmgenes.gr)
        colnames(sub_pair_dmgenes) <- lapply(colnames(sub_pair_dmgenes),
                                             function(i) paste('gene',i,sep='_'))
        meth_dmg_comb              <- cbind(sub_pair_p_meth,
                                            sub_pair_dmgenes)
        # label each scd if it is a dmsite
        #
        meth_dmg_comb['is.dm']                    <- FALSE
        meth_dmg_comb[pair_dmsites_index,'is.dm'] <- TRUE
        # save
        #
        meth_dmg_comb <- meth_dmg_comb[colSums(! is.na(meth_dmg_comb))>0]
        outfile <- paste("dmg",outflabel,sep="-")
        outfile <- paste(outfile,sample_match,sep="_")
        wtoutfile <- paste(outfile,"details.txt",sep="_")
        write.table(meth_dmg_comb, file=wtoutfile,
                    sep="\t", row.names=FALSE, quote=FALSE)
        # split the dataframe
        #
        splitter     <- c('gene_ID','gene_Name','gene_gene')
        splitter     <- splitter[splitter%in%names(meth_dmg_comb)][1]
        grouped      <- meth_dmg_comb %>% group_by_(.dots=splitter)
        out          <- split(grouped,grouped[splitter])
        # plot heatmap for each dmgene
        #
        phoutfile <- paste(outfile,"heatmaps.pdf",sep="_")
        pdf(phoutfile)
        lapply(out,function(g) {
            nsites <- dim(g)[1]
            pdmsites <- 100 * sum(g$is.dm,na.rm=TRUE) / nsites
            if (nsites >= min.nsites  &&  nsites <= max.nsites  &&
                pdmsites >= min.pdmsites) {
                plot <- as.matrix(g[,c(sample1,sample2)])
                # ... making sure that there are differences to show in the heatmap:
                if (nrow(plot) >= 2  &&  !all(plot[,1] == plot[,2])) {
                    heatmap.2(plot, 
                              margins=c(10,10),
                              dendrogram='none',
                              Rowv=FALSE,
                              col=greenred(10),
                              trace='none',
                              main=paste("Common sites",unique(g[splitter]),sep=" "),
                              srtCol=45,
                              RowSideColors=as.character(as.numeric(g$is.dm)))
                }
            }
        })
        dev.off()
        return(meth_dmg_comb)
    }, mc.cores=mc.cores)
    names(dmgprp) <- sample_match_list

    message('... show_dmsg() finished ...')
    return(dmgprp)
}
