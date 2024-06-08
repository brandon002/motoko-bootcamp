import Types "types";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
actor class Webpage(daoPrincipal : Principal) {

    type Result<A, B> = Result.Result<A, B>;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;

    // stable var manifesto : Text = "";
    // stable var goals : [Text] = [];
    stable var logo : Text = "<svg width='819' height='795' viewBox='0 0 819 795' fill='none' xmlns='http://www.w3.org/2000/svg'>
    <path d='M572.727 0V40.9091H654.545V81.8182H695.455V122.727H736.364V163.636H777.273V245.455H818.182V572.727H777.273V654.545H736.364V695.455H695.455V736.364H654.545V777.273H572.727V818.182H245.455V777.273H163.636V736.364H122.727V695.455H81.8182V654.545H40.9091V572.727H0V245.455H40.9091V163.636H81.8182V122.727H122.727V81.8182H163.636V40.9091H245.455V0H572.727ZM531.818 81.8182H286.364V122.727H204.545V163.636H163.636V204.545H122.727V286.364H81.8182V531.818H122.727V613.636H163.636V654.545H204.545V695.455H286.364V736.364H531.818V695.455H613.636V654.545H654.545V613.636H695.455V531.818H736.364V286.364H695.455V204.545H654.545V163.636H613.636V122.727H531.818V81.8182ZM286.364 204.545H490.909V245.455H531.818V368.182H490.909V450H531.818V572.727H490.909V613.636H286.364V204.545ZM368.182 286.364V368.182H450V286.364H368.182ZM450 450H368.182V531.818H450V450Z' fill='#264187'/>
    </svg>";
    stable var manifesto : Text = "";
    stable let name = "bnx";
    stable var goals = ["Explore DAO and build Dapps with Motoko"];
    let canisterDao = actor (Principal.toText(daoPrincipal)) : actor {
        getName : shared () -> async Text;
        getManifesto : shared query () -> async Text;
        getGoals : shared () -> async [Text];
        setManifesto : shared (newManifesto : Text) -> ();
        addGoal : shared (goal : Text) -> ();
    };
    public composite query func init() : async () {
        manifesto := await getManifesto();
    };
    func _getWebpage() : Text {
        var webpage = "<style>" #
        "body { text-align: center; font-family: Arial, sans-serif; background-color: #f0f8ff; color: #333; }" #
        "h1 { font-size: 3em; margin-bottom: 10px; }" #
        "hr { margin-top: 20px; margin-bottom: 20px; }" #
        "em { font-style: italic; display: block; margin-bottom: 20px; }" #
        "ul { list-style-type: none; padding: 0; }" #
        "li { margin: 10px 0; }" #
        "li:before { content: '👉 '; }" #
        "svg { max-width: 150px; height: auto; display: block; margin: 20px auto; }" #
        "h2 { text-decoration: underline; }" #
        "</style>";

        webpage := webpage # "<div><h1>" # name # "</h1></div>";
        webpage := webpage # "<em>" # manifesto # "</em>";
        webpage := webpage # "<div>" # logo # "</div>";
        webpage := webpage # "<hr>";
        webpage := webpage # "<h2>Our goals:</h2>";
        webpage := webpage # "<ul>";
        for (goal in goals.vals()) {
            webpage := webpage # "<li>" # goal # "</li>";
        };
        webpage := webpage # "</ul>";
        return webpage;
    };
    public query func http_request(request : HttpRequest) : async HttpResponse {
        return ({
            status_code = 200;
            headers = [("Content-Type", "text/html; charset=UTF-8")];
            body = Text.encodeUtf8(_getWebpage());
            streaming_strategy = null;
        });
    };

    public shared ({ caller }) func setManifesto(newManifesto : Text) : async Result<(), Text> {
        canisterDao.setManifesto(newManifesto);
        return #ok();
    };

    public shared composite query func getManifesto() : async Text {
        let res : Text = await canisterDao.getManifesto();
        return res;
    };

    public shared ({ caller }) func addGoal(goal : Text) : async Result<(), Text> {
        canisterDao.addGoal(goal);
        return #ok;
    };

    public func getGoals() : async [Text] {
        return await canisterDao.getGoals();
    };
};
