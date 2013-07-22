function varargout = confusion2roc(confusion)
% function [TPR,FPR,K_1_0,K_0_0, CohensKappa,PPV,NPV, ACC, precision, recall, f_measure] = confusion2roc(confusion)
%takes a Nx4 confusion matrix of the form [TP,FN,FP,TN] where these are in
%percentages from 0..1 - i
%the values of Q will be normalized by the sum if any are above 1, where it
%will be assumed that the values represent counts as opposed to
%percentages...
%[rocStruct] = confusion2roc(confusion)
% if only one output is provided then the structure rocStruct is returned
% which contains the above output arguments (e.g. TPR, FPR, etc. as its fields
%
% rocDescriptionStruct = confusion2roc()
% rocDescriptionStruct has the same fields as rocStruct, but each field
% value contains a string description of the field, useful for table or
% plot labeling.

%Written: Hyatt Moore, IV
% date: < June, 2013

rocStruct.TPR = [];
rocStruct.FPR = [];
rocStruct.Specificity = [];
rocStruct.PPV = [];
rocStruct.NPV = [];
rocStruct.K_1_0 = [];
rocStruct.K_0_0 = [];
rocStruct.CohensKappa = [];
rocStruct.f_measure = [];
rocStruct.Accuracy = [];
%         rocStruct.precision = precision;
%         rocStruct.recall = recall;

if(nargin>0)
    TP = confusion(:,1);
    FN = confusion(:,2);
    FP = confusion(:,3);
    TN = confusion(:,4);
    
    P = TP + FN;
    Q = TP + FP;
    
    SE = TP./P;
    SP = TN./(1-P);
    TPR = SE;
    FPR = 1 - SP;
    precision = TP./(TP+FP); %TP/Q = PPV
    recall = TP./P; %same as sensitivity same as TPR;
    
    K_1_0 = (SE-Q)./(1-Q);
    K_0_0 = (SP-(1-Q))./Q;
    
%     nans = isnan(K_1_0(:))|isnan(K_0_0(:));
    

    
    N = FP+TN;
    ACC = (TP + TN) ./ (P + N);
    
    f_measure = 2/(1/precision+1/recall);
    %page 116 in Kramer's book  Evaluating Medical Tests
    % [PQ'*K(1,0)+P'Q*K(0,0)]/(PQ'+P'Q)
   
    CohensKappa = (P.*(1-Q).*K_1_0+(1-P).*Q.*K_0_0)./(P.*(1-Q)+(1-P).*Q);
    PPV = TP./Q;
    NPV = TN./(1-Q);
    
    
    if(nargout==1)
        rocStruct.TPR = TPR;
        rocStruct.FPR = FPR;
        rocStruct.Specificity = 1 - FPR;
        
        rocStruct.PPV = PPV;
        rocStruct.NPV = NPV;
        rocStruct.K_1_0 = K_1_0;
        rocStruct.K_0_0 = K_0_0;
        rocStruct.CohensKappa = CohensKappa;
%         rocStruct.precision = precision;
%         rocStruct.recall = recall;
        rocStruct.f_measure = f_measure;
        rocStruct.Accuracy = ACC;
        varargout{1} = rocStruct; 
    else
        varargout{1} = TPR;
        varargout{2} = FPR;
        varargout{3} = K_1_0;
        varargout{4} = K_0_0;
        varargout{5} = CohensKappa;
        varargout{6} = PPV;
        varargout{7} = NPV;
        varargout{8} = precision;
        varargout{9} = recall;
        varargout{10} = f_measure;
        varargout{11} = ACC;
        

    end
    
else %no input arguments provided
    fields = fieldnames(rocStruct);
    for f=1:numel(fields)
        cur_field = fields{f};
        switch cur_field
            case 'TPR'
                str = 'Sensitivity';
            case 'FPR'
                str = '1-Specificity';
            case 'PPV'
                str = 'Positive Predictive Value (PPV)';
            case 'NPV'
                str = 'Negative Predictive Value (NPV)';
            case 'CohensKappa'
                str = 'Cohen''s Kappa';
            case 'f_measure'
                str = 'F score';
            case 'confusion'
                str = 'Confusion Matrix [TP,FN,FP,TN]';
            case 'K_1_0'
                str = 'Kappa(1,0)';
            case 'K_0_0'
                str = 'Kappa(0,0)';            
            otherwise
                str = cur_field;
        end
        rocStruct.(cur_field) = str;
    end
    varargout{1} = rocStruct;    
end

    

