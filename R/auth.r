#' Put a cushion on the sofa, and get cushion info
#'
#' That is, set up config for remote CouchDB databases, or get auth info
#'
#' @name authentication
#' @param name Name for the cushion. This is what you'll call in sofa functions to get these
#' details.
#' @param user A user name
#' @param pwd A password
#' @param base A base URL, not needed if \code{type=localhost|cloudant|iriscouch}. Though
#' you can pass a base URL in here to override anything done internally.
#' @param type One of localhost, cloudant, iriscouch, or \code{NULL}. This is what's
#' used to determine how to structure the URL to make the request. If left to the
#' default of \code{NULL}, you must pass in a base URL.
#' @param port Port. Only applies when type is localhost. Default: 5984
#' @param authfile Path to file with cushions (authentication details)
#' @details Setup for authentication:
#' For localhost you don't need to authenticate, but of course you may have set
#' up a username and password in which case use 'localhost'.
#'
#' Others supported are 'cloudant' and 'iriscouch'.
#'
#' You can use other named username/password sets too.
#'
#' You can permanently store your auth details in a hidden file ~/.sofa-auth by putting in
#' entries like this, each on a new line:
#'
#' list(name="iriscouch", user="jane_doe", pwd="my_password", type="iriscouch")
#'
#' Though if you don't want to store them permanently, you can use the \code{cushion}
#' function instead. See examples below on how to do this. Using \code{cushion} only
#' stores them for the current session.
#'
#' \code{cushions()} Looks first in the local environment SofaAuthCache, and if finds nothing,
#' looks in your \code{~/.sofa-auth} file, or wherver you set \code{authfilie} parameter to.
#'
#' Beware that you should use unique names for each cushion, that is, in the \code{name} parameter.
#' @examples \dontrun{
#' cushion('cloudant', user='name', pwd='pwd', type="cloudant")
#' cushion('iriscouch', user='name', pwd='pwd', type="iriscouch")
#' cushion('julies_iris', user='name', pwd='pwd', type="iriscouch")
#' cushion('adfafafafadf', user='name', pwd='pwd', type="localhost", port=2300)
#' cushions()
#'
#' cushion("oceancouch", base="http://104.236.176.205", port=5984)
#' }

#' @export
#' @rdname authentication
cushion <- function(name, user=NULL, pwd=NULL, base=NULL, type=NULL, port=5984){
  assign(name, list(user=user, pwd=pwd, base=base, type=type, port=port), envir = SofaAuthCache)
}

#' @export
#' @rdname authentication
cushions <- function(authfile = "~/.sofa-auth")
{
  # make file if doesn't exist
  if(!file.exists(authfile)) cat("", file = authfile)
  lns <- readLines(authfile)
  profs <- lapply(lns, makelist)
  temp <- mget(ls(SofaAuthCache), envir=SofaAuthCache)
  nms <- unlist(c(sapply(profs, function(x) names(x)), sapply(list(temp), function(x) names(x))))
  if(length(nms) != 0) dups <- paste0(sapply(nms[ duplicated(nms) ], function(x) sprintf('"%s"', x)), collapse = " ")
  if(any(duplicated(nms))) stop(sprintf("%s found in both cached auth file and in the current session", dups))
  comb <- do.call(c, c(profs, list(temp)))
  if(length(comb) == 0)
    stop("No auth details found")
  else
    lapply(comb, function(x) structure(x, class="sofa_profile"))
}

makelist <- function(x){
  tmp <- eval(parse(text=x))
  aname <- tmp$name
  tmp <- tmp[ !names(tmp) %in% "name" ]
  structure(list(tmp), .Names=aname)
}

#' @export
print.sofa_profile <- function(x, ...){
  cat("<sofa profile> ", sep = "\n")
  cat(paste0("   user : ", x$user), sep = "\n")
  cat(paste0("   pwd  : ", x$pwd), sep = "\n")
  cat(paste0("   base : ", x$base), sep = "\n")
  cat(paste0("   type : ", x$type), sep = "\n")
  cat(paste0("   port : ", x$port), sep = "\n")
}

# sofa environment
SofaAuthCache <- new.env(hash=TRUE)

.onLoad <- function(...) {
  assign("localhost", list(user=NULL, pwd=NULL, base=NULL, type="localhost", port=5984), envir = SofaAuthCache)
}

get_cushion <- function(x){
  profs <- cushions()
  res <- profs[ names(profs) %in% x ]
  if(length(res) == 0) stop(paste0(x, " not found, see ?cushion and ?profiles")) else res[[1]]
}
