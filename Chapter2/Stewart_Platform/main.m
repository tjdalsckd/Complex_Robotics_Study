addpath('mr')
p_list = [sqrt(3)/2 -0.5 0;
         0 1 0;
         -sqrt(3)/2 -0.5 0;
         sqrt(3)/2 0.5 1;
         -sqrt(3)/2 0.5 1;
         0 -1 1];

connection_list = [1,4;
                   2,4;
                   2,5;
                   3,5;
                   3,6;
                   1,6]
drawConnection(p_list,connection_list)
LEG_NUM = 6
leg_w_list = [1,0,0;
          0,1,0;
          0,0,1;
          0,0,0;
          1,0,0;
          0,1,0;
          0,0,1]
Leg_Slist={}
Leg_Blist={}
Leg_M={}
for i =1:1:LEG_NUM
    ind=connection_list(i,:);
    leg_p_list = [p_list(ind(1),:);
                  p_list(ind(1),:);
                  p_list(ind(1),:);
                  0,0,0;
                  p_list(ind(2),:);
                  p_list(ind(2),:);
                  p_list(ind(2),:)]
    ei = p_list(ind(2),:)-p_list(ind(1),:);
    ei = ei/norm(ei);
    leg_Slist = []
    for j = 1:1:length(leg_w_list)
        
        if j==4
            S = [0 0 0 ei]';
        else
            S = [leg_w_list(j,:)'; -cross(leg_w_list(j,:)',leg_p_list(j,:)')];
        end
        leg_Slist = [leg_Slist,S];
    end
    Leg_Slist{i} = leg_Slist;
    
    M = [-1 0 0 0;
         0 -1 0 0;
         0 0 1 1;
         0 0 0 1]
    Leg_Blist{i} = Adjoint(TransInv(M))*leg_Slist;
    Leg_M{i} = M;
end

endTime = 5
dt = 0.1;
q_a = [0,0,0,0,0,0]';
qdot_a = [0.1,0,0.1,0,0.1,0]';
q_p = zeros(36,1);
qdot_p = zeros(36,1);
q={};
Jb={};
for i=1:1:LEG_NUM
    q{i}=zeros(6,1);
    Jb{i} = JacobianBody(Leg_Blist{i},q{i})
end
 for t = linspace(0,endTime,floor(endTime/dt))
    q = getq(q_a,q_p,LEG_NUM);
    qdot = getq(qdot_a,qdot_p,LEG_NUM);
    for i=1:1:LEG_NUM
        Jb{i} = JacobianBody(Leg_Blist{i},q{i})
    end
    
    O = zeros(size(Jb{1}));
    Jc = [Jb{1}     -Jb{2}      O       O   O       O;
              O     -Jb{2}   Jb{3}      O   O       O;
              O         O    Jb{3} -Jb{4}   O       O;
              O         O       O  -Jb{4}   Jb{5}   O;
              O         O       O       O   Jb{5}   -Jb{6}]
    
    Ha = Jc(:,4:7:end);
    Hp = Jc;
    Hp(:,4:7:end) = [];
    H = [Ha, Hp];
    g = -pinv(Hp)*Ha;
    qdot_p = g*qdot_a;
    e1 = [1,0,0,0,0,0]';
    tempq = [q{1};
             q{2};
             q{3};
             q{4};
             q{5};
             q{6}]
    Ja = Jb{1}*[g(1,:);g(2,:);g(3,:);e1';g(5,:);g(6,:);g(7,:) ];
    VT = [0,0,0,0,0,0.01]';
    qdot_a = pinv(Ja)*VT;
    qdot_p = g*qdot_a;
    [q_a,qdot_a] =   EulerStep(q_a,qdot_a,zeros(size(q_a)),dt);
    [q_p,qdot_p] =   EulerStep(q_p,qdot_p,zeros(size(q_p)),dt);

    ax = axes();
    cla
    hold on;
    drawRobot(ax,q_a,q_p,LEG_NUM,Leg_Slist,Leg_M);
    daspect([1,1,1])
    drawnow;
    
  end

% 
% linelength = 1
% lineWidth = 1
% T0 = eye(4)
% T = RpToTrans(eul2rotm([pi/3,pi/3,pi/3]),[1,1,1]')
% opacity = 1
% txt = ""
% figure(1);
% ax = axes();
% actuated_flag =0;
% hold on;
% drawAxis(T,linelength ,lineWidth,T0,opacity,txt,ax,actuated_flag)
function q = getq(q_a,q_p,LEG_NUM)
    n_a = length(q_a);
    n_p = length(q_p);
    q =zeros(n_a+n_p,1);
    count_a = 1;
    count_p = 1;
    for j =1:1:(n_a+n_p)
        if mod(j,7)==4
            q(j) = q_a(count_a);
            count_a = count_a+1;
        else
            q(j) = q_p(count_p);
            count_p = count_p+1;
        end
    end
    q_temp = q;
    q={};
    for i = 1:1:LEG_NUM
        q{i} = q_temp((i-1)*LEG_NUM+1:(i-1)*LEG_NUM+7);
    end
end
function drawConnection(p_list,connection_list)
    fill3([p_list(1,1) p_list(2,1) p_list(3,1) p_list(1,1)],[p_list(1,2) p_list(2,2) p_list(3,2) p_list(1,2)],[p_list(1,3) p_list(2,3) p_list(3,3) p_list(1,3)],'k',FaceAlpha=0.1) ; hold on;
    fill3([p_list(4,1) p_list(5,1) p_list(6,1) p_list(4,1)],[p_list(4,2) p_list(5,2) p_list(6,2) p_list(4,2)],[p_list(4,3) p_list(5,3) p_list(6,3) p_list(4,3)],'k',FaceAlpha=0.1) ; hold on;
    for i = 1:1:length(connection_list)
        ind = connection_list(i,:)
        plot3([p_list(ind(1),1), p_list(ind(2),1)],[p_list(ind(1),2), p_list(ind(2),2)],[p_list(ind(1),3), p_list(ind(2),3)])
    end

    grid on;
end