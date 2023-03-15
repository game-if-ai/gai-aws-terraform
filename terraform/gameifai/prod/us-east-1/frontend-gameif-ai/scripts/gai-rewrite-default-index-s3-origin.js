/**
 * Rewrites origin (s3 bucket) requests to index.html for all client apps
 * 
 * @param {*} event 
 * @returns 
 */
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (["PATCH", "PUT", "POST", "DELETE"].includes(request.method)) {
    return request;
  }

  // This re-routes a route-less url (mentorpal.org) to the /home/ route
  // if (uri == "" || uri == "/") {
  //   var response = {
  //     statusCode: 302,
  //     statusDescription: "Found",
  //     headers: { location: { value: "/home/" } },
  //   };

  //   return response;
  // }

  if (!uri.includes(".")) {
    var uriRoutes = uri.split("/").filter(e=>e.length)
    if(uriRoutes.length > 0){
        request.uri = "/" + uriRoutes.join("/") +"/index.html";
    }else{
        request.uri = "/index.html";
    }
  }

  return request;
}
