import Types "types";
import Result "mo:base/Result";
import Text "mo:base/Text";
actor class Webpage(daoPrincipal : Principal) = this {

    type Result<A, B> = Result.Result<A, B>;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;

    stable var manifesto : Text = "";
    stable var goals : [Text] = [];
    stable var logo : Text = "";

    public query func http_request(request : HttpRequest) : async HttpResponse {
        return ({
            status_code = 404;
            headers = [];
            body = Text.encodeUtf8("Hello world!");
            streaming_strategy = null;
        });
    };

    public shared ({ caller }) func setManifesto(newManifesto : Text) : async Result<(), Text> {
        return #err("Not implemented");
    };

    public func getManifesto() : async Text {
        return "Not implemented";
    };

    public shared ({ caller }) func addGoal(goal : Text) : async Result<(), Text> {
        return #err("Not implemented");
    };

    public func getGoals() : async [Text] {
        return [];
    };
};
